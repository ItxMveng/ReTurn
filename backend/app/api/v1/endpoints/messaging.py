import json
import uuid

from fastapi import (
    APIRouter,
    Depends,
    File,
    HTTPException,
    Query,
    UploadFile,
    WebSocket,
    WebSocketDisconnect,
    status,
)
from jose import JWTError, jwt
from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.database import AsyncSessionLocal, get_db
from app.core.dependencies import get_current_user
from app.core.redis_client import get_redis
from app.core.ws_manager import broadcast, register, unregister
from app.models.match import Match
from app.models.message import Message
from app.models.user import User
from app.schemas.message import MessageRead, WsOutgoing
from app.schemas.report import ReportCreate, ReportRead
from app.services import messaging_service, verification_service, report_service
from app.services.notification_service import push_message_notification
from app.schemas.verification import VerificationRead

router = APIRouter(prefix="/messaging", tags=["messaging"])


# ── REST: history & verification ─────────────────────────────────────────────

@router.get("/{match_id}/messages", response_model=list[MessageRead])
async def get_history(
    match_id: uuid.UUID,
    limit: int = Query(50, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    await _assert_participant(db, match_id, current_user.id)
    messages = await messaging_service.get_history(db, match_id, limit)
    await messaging_service.mark_read(db, match_id, current_user.id)
    return messages


@router.post("/{match_id}/verify", response_model=VerificationRead)
async def request_verification(
    match_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    await _assert_participant(db, match_id, current_user.id)
    verif = await verification_service.request_verification(
        db, match_id, current_user.id
    )
    return verif


@router.post("/{match_id}/verify/selfie", response_model=VerificationRead)
async def submit_selfie(
    match_id: uuid.UUID,
    selfie: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    await _assert_participant(db, match_id, current_user.id)
    verif = await verification_service.get_verification(db, match_id, current_user.id)
    if not verif:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Demande de vérification introuvable",
        )
    content = await selfie.read()
    return await verification_service.submit_selfie(
        db, verif, content, selfie.content_type or "image/jpeg"
    )


@router.get("/{match_id}/verify", response_model=VerificationRead | None)
async def get_verification_status(
    match_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    await _assert_participant(db, match_id, current_user.id)
    return await verification_service.get_verification(db, match_id, current_user.id)


# ── Signalement / Litige ──────────────────────────────────────────────────────

@router.post(
    "/{match_id}/report",
    response_model=ReportRead,
    status_code=status.HTTP_201_CREATED,
    summary="Signaler un utilisateur dans un match",
)
async def report_user(
    match_id: uuid.UUID,
    payload: ReportCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Permet à un participant d'un match de signaler l'autre utilisateur.
    - Vérifie que le déclarant est bien participant du match.
    - Vérifie que l'utilisateur signalé est bien l'autre participant.
    - Crée le signalement en base et notifie l'admin.
    """
    await _assert_participant(db, match_id, current_user.id)

    # Vérifier que reported_id est bien l'autre participant du match
    match = await _get_match(db, match_id, current_user.id)
    other_id = (
        match.user_lost_id
        if match.user_found_id == current_user.id
        else match.user_found_id
    )
    if payload.reported_id != other_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="L'utilisateur signalé doit être l'autre participant du match",
        )

    # Empêcher l'auto-signalement
    if payload.reported_id == current_user.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Vous ne pouvez pas vous signaler vous-même",
        )

    report = await report_service.create_report(
        db=db,
        match_id=match_id,
        reporter=current_user,
        payload=payload,
    )
    return report


# ── WebSocket ─────────────────────────────────────────────────────────────────

@router.websocket("/{match_id}/ws")
async def websocket_chat(
    match_id: uuid.UUID,
    ws: WebSocket,
    token: str = Query(...),
):
    user = await _authenticate_ws(token)
    if user is None:
        await ws.close(code=4001)
        return

    async with AsyncSessionLocal() as db:
        match = await _get_match(db, match_id, user.id)
        if match is None:
            await ws.close(code=4003)
            return

    await ws.accept()
    match_key = str(match_id)
    register(match_key, ws)

    await ws.send_text(json.dumps({
        "type": "system",
        "content": f"Connecté au chat du match {match_id}",
    }))

    try:
        while True:
            raw = await ws.receive_text()
            try:
                data = json.loads(raw)
                content = str(data.get("content", "")).strip()
                msg_type = str(data.get("message_type", "text"))
                if not content:
                    continue
            except (json.JSONDecodeError, ValueError):
                continue

            async with AsyncSessionLocal() as db:
                redis = await get_redis()
                msg = await messaging_service.save_message(
                    db, redis, match_id, user.id, content, msg_type
                )
                outgoing = WsOutgoing(
                    id=str(msg.id),
                    match_id=str(msg.match_id),
                    sender_id=str(msg.sender_id),
                    content=msg.content,
                    message_type=msg.message_type,
                    created_at=msg.created_at.isoformat(),
                    is_read=msg.is_read,
                )
                await broadcast(match_key, outgoing.model_dump_json())

                match_obj = await _get_match(db, match_id, user.id)
                if match_obj:
                    other_id = (
                        match_obj.user_lost_id
                        if match_obj.user_found_id == user.id
                        else match_obj.user_found_id
                    )
                    res_other = await db.execute(
                        select(User).where(User.id == other_id)
                    )
                    other_user = res_other.scalar_one_or_none()
                    if other_user and other_user.fcm_token:
                        sender_name = user.full_name or user.phone_number or "Utilisateur"
                        await push_message_notification(
                            fcm_token=other_user.fcm_token,
                            match_id=match_id,
                            sender_name=sender_name,
                            preview=content,
                        )

    except WebSocketDisconnect:
        unregister(match_key, ws)


# ── Helpers ───────────────────────────────────────────────────────────────────

async def _assert_participant(
    db: AsyncSession, match_id: uuid.UUID, user_id: uuid.UUID
) -> None:
    result = await db.execute(
        select(Match).where(
            Match.id == match_id,
            or_(Match.user_found_id == user_id, Match.user_lost_id == user_id),
        )
    )
    if not result.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Accès refusé à ce match",
        )


async def _get_match(
    db: AsyncSession, match_id: uuid.UUID, user_id: uuid.UUID
) -> Match | None:
    result = await db.execute(
        select(Match).where(
            Match.id == match_id,
            or_(Match.user_found_id == user_id, Match.user_lost_id == user_id),
        )
    )
    return result.scalar_one_or_none()


async def _authenticate_ws(token: str) -> User | None:
    try:
        payload = jwt.decode(
            token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM]
        )
        user_id = payload.get("sub")
        if not user_id:
            return None
    except JWTError:
        return None

    async with AsyncSessionLocal() as db:
        result = await db.execute(
            select(User).where(
                User.id == uuid.UUID(user_id),
                User.is_active == True,  # noqa: E712
            )
        )
        return result.scalar_one_or_none()
