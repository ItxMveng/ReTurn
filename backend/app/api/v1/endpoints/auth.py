import logging
import secrets
import uuid

from pydantic import BaseModel

from fastapi import APIRouter, Depends, HTTPException, Request, status
from jose import JWTError, jwt
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.database import get_db
from app.core.redis_client import get_redis
from app.core.firebase_admin import verify_firebase_token
from app.schemas.auth import FirebaseTokenRequest, OTPRequest, OTPVerify, RefreshRequest, TokenResponse
from app.schemas.user import UserRead
from app.services.auth_service import get_or_create_user, issue_tokens
from app.services.otp_service import create_otp, verify_otp
from app.core.dependencies import get_current_user
from app.models.user import User
from app.models.connection_log import ConnectionLog, ConnectionStatus

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/auth", tags=["auth"])


# ── Helper : enregistrement log de connexion ──────────────────────────────────

def _extract_ip(request: Request) -> str | None:
    forwarded = request.headers.get("X-Forwarded-For")
    if forwarded:
        return forwarded.split(",")[0].strip()
    return request.client.host if request.client else None


async def _log_connection(
    db: AsyncSession,
    request: Request,
    status: ConnectionStatus,
    user_id: uuid.UUID | None = None,
    phone_number: str | None = None,
    auth_method: str = "otp",
) -> None:
    """Enregistre une tentative de connexion en base (traçabilité légale)."""
    log = ConnectionLog(
        user_id=user_id,
        phone_number=phone_number,
        ip_address=_extract_ip(request),
        user_agent=request.headers.get("User-Agent"),
        device_id=request.headers.get("X-Device-ID"),
        auth_method=auth_method,
        status=status,
    )
    db.add(log)
    await db.flush()  # persist dans la même transaction


# ── Endpoints ────────────────────────────────────────────────────────────────────

@router.post("/verify-firebase-token", response_model=TokenResponse)
async def verify_firebase_token_endpoint(
    body: FirebaseTokenRequest,
    request: Request,
    db: AsyncSession = Depends(get_db),
):
    try:
        decoded = verify_firebase_token(body.firebase_token)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token Firebase invalide ou expiré.",
        ) from e
    except Exception:
        logger.exception("Erreur inattendue lors de la vérification Firebase")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur serveur.",
        )

    firebase_uid: str = decoded["uid"]
    phone_number: str | None = decoded.get("phone_number")
    email: str | None = decoded.get("email")

    is_email_auth = phone_number is None and email is not None
    identifier = email if is_email_auth else phone_number
    if not identifier:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token Firebase sans numéro de téléphone ni email.",
        )

    user, is_new = await get_or_create_user(
        db,
        identifier,
        firebase_uid=firebase_uid,
        email=email if is_email_auth else None,
        is_email_auth=is_email_auth,
    )

    # — Promotion admin déclarative (sans shell) : si le numéro figure dans
    #   ADMIN_PHONE_NUMBERS, on garantit is_admin=true à chaque connexion. —
    if (
        phone_number
        and phone_number.replace(" ", "") in settings.admin_phone_set
        and not getattr(user, "is_admin", False)
    ):
        user.is_admin = True
        db.add(user)

    # — Log connexion Firebase —
    conn_status = ConnectionStatus.BANNED if getattr(user, "is_banned", False) else ConnectionStatus.SUCCESS
    await _log_connection(
        db, request,
        status=conn_status,
        user_id=user.id,
        phone_number=phone_number,
        auth_method="firebase",
    )
    await db.commit()

    if getattr(user, "is_banned", False):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Ce compte a été suspendu. Contactez le support.",
        )

    tokens = await issue_tokens(user)
    tokens.is_new_user = is_new
    return tokens


class AdminLoginRequest(BaseModel):
    phone_number: str
    secret: str


@router.post("/admin-login", response_model=TokenResponse)
async def admin_login(
    body: AdminLoginRequest,
    request: Request,
    db: AsyncSession = Depends(get_db),
):
    """Connexion au panneau d'administration sans SMS.

    En production, l'OTP custom n'envoie pas de SMS : le panel admin s'appuie
    donc sur un secret (ADMIN_BOOTSTRAP_SECRET) + un numéro déclaré admin
    (ADMIN_PHONE_NUMBERS). Sécurisé par comparaison à temps constant.
    """
    configured = settings.ADMIN_BOOTSTRAP_SECRET.strip()
    if not configured:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Connexion admin non configurée sur ce serveur.",
        )

    # Comparaison du secret à temps constant (on tolère les espaces parasites
    # que Render ajoute parfois aux valeurs collées).
    secret_ok = secrets.compare_digest(body.secret.strip(), configured)

    # Numéro : comparaison tolérante au format (+237 optionnel, espaces).
    def _digits(p: str) -> str:
        return "".join(c for c in p if c.isdigit())

    phone = body.phone_number.strip().replace(" ", "")
    input_digits = _digits(phone)
    phone_ok = any(
        input_digits == _digits(a) or input_digits[-9:] == _digits(a)[-9:]
        for a in settings.admin_phone_set
        if _digits(a)
    )
    if not (secret_ok and phone_ok):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Numéro ou secret admin invalide.",
        )

    # Retrouve l'utilisateur : correspondance exacte, sinon sur les 9 derniers
    # chiffres (tolère le format du numéro stocké).
    result = await db.execute(select(User).where(User.phone_number == phone))
    user = result.scalar_one_or_none()
    if user is None and len(input_digits) >= 9:
        # Tolère le format stocké (+237… vs 6…) via les 9 derniers chiffres.
        suffix = input_digits[-9:]
        user = (
            await db.execute(
                select(User).where(User.phone_number.like(f"%{suffix}"))
            )
        ).scalars().first()
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Connectez-vous d'abord à l'application mobile avec ce numéro.",
        )
    if getattr(user, "is_banned", False):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="Compte suspendu."
        )
    if not user.is_admin:
        user.is_admin = True
        db.add(user)

    await _log_connection(
        db, request,
        status=ConnectionStatus.SUCCESS,
        user_id=user.id,
        phone_number=phone,
        auth_method="admin_secret",
    )
    await db.commit()
    return await issue_tokens(user)


@router.post("/otp/request", status_code=status.HTTP_200_OK)
async def request_otp(body: OTPRequest, redis=Depends(get_redis)):
    code = await create_otp(redis, body.phone_number)
    # TODO: envoyer le code via SMS (Twilio / Orange CM)
    logger.info("OTP demandé pour %s", body.phone_number)
    expose_code = settings.DEBUG and settings.ENVIRONMENT != "production"
    return {
        "detail": "Code OTP envoyé",
        "debug_code": code if expose_code else None,
    }


@router.post("/otp/verify", response_model=TokenResponse)
async def verify_otp_endpoint(
    body: OTPVerify,
    request: Request,
    db: AsyncSession = Depends(get_db),
    redis=Depends(get_redis),
):
    valid = await verify_otp(redis, body.phone_number, body.otp_code)

    if not valid:
        # Log tentative échouée (OTP invalide)
        await _log_connection(
            db, request,
            status=ConnectionStatus.FAILED,
            phone_number=body.phone_number,
            auth_method="otp",
        )
        await db.commit()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Code OTP invalide ou expiré",
        )

    user, is_new = await get_or_create_user(db, body.phone_number)

    # Log connexion OTP réussie (ou banni)
    conn_status = ConnectionStatus.BANNED if getattr(user, "is_banned", False) else ConnectionStatus.SUCCESS
    await _log_connection(
        db, request,
        status=conn_status,
        user_id=user.id,
        phone_number=body.phone_number,
        auth_method="otp",
    )
    await db.commit()

    if getattr(user, "is_banned", False):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Ce compte a été suspendu. Contactez le support.",
        )

    tokens = await issue_tokens(user)
    tokens.is_new_user = is_new
    return tokens


@router.post("/refresh", response_model=TokenResponse)
async def refresh_tokens(
    body: RefreshRequest,
    db: AsyncSession = Depends(get_db),
):
    try:
        payload = jwt.decode(
            body.refresh_token,
            settings.SECRET_KEY,
            algorithms=[settings.ALGORITHM],
        )
        if payload.get("type") != "refresh":
            raise ValueError("Not a refresh token")
        user_id: str = payload["sub"]
    except (JWTError, ValueError, KeyError):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Refresh token invalide",
        )

    result = await db.execute(select(User).where(User.id == uuid.UUID(user_id)))
    user = result.scalar_one_or_none()
    if not user or not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Utilisateur introuvable",
        )

    return await issue_tokens(user)


@router.get("/me", response_model=UserRead)
async def get_me(current_user: User = Depends(get_current_user)):
    return current_user
