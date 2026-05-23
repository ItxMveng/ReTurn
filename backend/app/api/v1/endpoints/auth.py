import logging

from fastapi import APIRouter, Depends, HTTPException, status
from jose import JWTError, jwt
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

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/verify-firebase-token", response_model=TokenResponse)
async def verify_firebase_token_endpoint(
    body: FirebaseTokenRequest,
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

    # Les connexions Google n'ont pas de phone_number dans le token Firebase.
    # On utilise l'email comme identifiant de repli pour créer le compte.
    identifier = phone_number or email
    if not identifier:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token Firebase sans numéro de téléphone ni email.",
        )

    user, is_new = await get_or_create_user(
        db, identifier, firebase_uid=firebase_uid, email=email
    )
    tokens = await issue_tokens(user)
    tokens.is_new_user = is_new
    return tokens


@router.post("/otp/request", status_code=status.HTTP_200_OK)
async def request_otp(body: OTPRequest, redis=Depends(get_redis)):
    code = await create_otp(redis, body.phone_number)
    # TODO: envoyer le code via SMS (Twilio / Orange CM)
    logger.info("OTP demandé pour %s", body.phone_number)
    return {"detail": "Code OTP envoyé", "debug_code": code if settings.DEBUG else None}


@router.post("/otp/verify", response_model=TokenResponse)
async def verify_otp_endpoint(
    body: OTPVerify,
    db: AsyncSession = Depends(get_db),
    redis=Depends(get_redis),
):
    valid = await verify_otp(redis, body.phone_number, body.otp_code)
    if not valid:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Code OTP invalide ou expiré")

    user, is_new = await get_or_create_user(db, body.phone_number)
    tokens = await issue_tokens(user)
    tokens.is_new_user = is_new
    return tokens


@router.post("/refresh", response_model=TokenResponse)
async def refresh_tokens(body: RefreshRequest, db: AsyncSession = Depends(get_db)):
    try:
        payload = jwt.decode(body.refresh_token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        if payload.get("type") != "refresh":
            raise ValueError
        user_id: str = payload["sub"]
    except (JWTError, ValueError, KeyError):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Refresh token invalide")

    from sqlalchemy import select
    import uuid
    result = await db.execute(select(User).where(User.id == uuid.UUID(user_id)))
    user = result.scalar_one_or_none()
    if not user or not user.is_active:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Utilisateur introuvable")

    return await issue_tokens(user)


@router.get("/me", response_model=UserRead)
async def get_me(current_user: User = Depends(get_current_user)):
    return current_user
