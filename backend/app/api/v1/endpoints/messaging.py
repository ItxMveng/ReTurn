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
from sqlalchemy import func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.database import AsyncSessionLocal, get_db
from app.core.dependencies import get_current_user
from app.core.redis_client import get_redis
from app.core.ws_manager import broadcast, register, unregister
from app.models.declaration import Declaration
from app.models.match import Match
from app.models.message import Message
from app.models.user import User
from app.schemas.message import (
    ConversationRead,
    MessageRead,
    WsIncoming,
    WsOutgoing,
)
from app.schemas.report import ReportCreate, ReportRead
from app.services import messaging_service, verification_service, report_service
from app.services.notification_service import push_message_notification
from app.schemas.verification import ControlAnswers, VerificationRead

router = APIRouter(prefix="/messaging", tags=["messaging"])


# ── REST: liste des conversations ─────────────────────────────────────────────

@router.get("/conversations", response_model=list[ConversationRead])
async def list_conversations(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Liste les conversations de l'utilisateur (une par match).

    Chaque match auquel l'utilisateur participe devient une conversation, avec
    le nom de l'autre participant, le dernier message et le nombre de non-lus.
    """
    # Une conversation n'apparaît QU'APRÈS vérification d'identité : le match
    # passe à "confirmed" uniquement quand le propriétaire a validé son identité
    # (verification_service._on_approved). Avant cela → aucun chat visible.
    result = await db.execute(
        select(Match).where(
            or_(
                Match.user_found_id == current_user.id,
                Match.user_lost_id == current_user.id,
            ),
            Match.status == "confirmed",
        )
    )
    matches = list(result.scalars().all())

    conversations: list[ConversationRead] = []
    for match in matches:
        other_id = (
            match.user_lost_id
            if match.user_found_id == current_user.id
            else match.user_found_id
        )
        other = (
            await db.execute(select(User).where(User.id == other_id))
        ).scalar_one_or_none()

        last = (
            await db.execute(
                select(Message)
                .where(Message.match_id == match.id)
                .order_by(Message.created_at.desc())
                .limit(1)
            )
        ).scalar_one_or_none()

        unread = (
            await db.execute(
                select(func.count())
                .select_from(Message)
                .where(
                    Message.match_id == match.id,
                    Message.sender_id != current_user.id,
                    Message.is_read == False,  # noqa: E712
                )
            )
        ).scalar() or 0

        other_name = "Utilisateur"
        if other is not None:
            other_name = (
                getattr(other, "full_name", None)
                or getattr(other, "phone_number", None)
                or "Utilisateur"
            )

        conversations.append(
            ConversationRead(
                room_id=str(match.id),
                other_user_name=other_name,
                other_user_avatar=getattr(other, "avatar_url", None)
                if other is not None
                else None,
                last_message=last.content if last else None,
                last_at=(
                    last.created_at.isoformat()
                    if last
                    else match.created_at.isoformat()
                ),
                unread=int(unread),
            )
        )

    conversations.sort(key=lambda c: c.last_at or "", reverse=True)
    return conversations


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


@router.post(
    "/{match_id}/messages",
    response_model=MessageRead,
    status_code=status.HTTP_201_CREATED,
)
async def send_message(
    match_id: uuid.UUID,
    payload: WsIncoming,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
    redis=Depends(get_redis),
):
    """Envoi REST d'un message (complément au WebSocket pour les clients simples)."""
    match = await _get_match(db, match_id, current_user.id)
    if not match:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="Accès refusé à ce match"
        )
    # La conversation ne s'ouvre qu'après vérification d'identité (match
    # "confirmed"). Tant que le match est "pending", aucun échange possible.
    if match.status != "confirmed":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="La conversation n'est pas encore ouverte."
            if match.status == "pending"
            else "La conversation est fermée.",
        )
    content = payload.content.strip()
    if not content:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Message vide.",
        )
    msg = await messaging_service.save_message(
        db, redis, match_id, current_user.id, content, payload.message_type
    )
    return msg


def _assert_owner(match: Match, user_id: uuid.UUID) -> None:
    """Seul le PROPRIÉTAIRE présumé (déclarant de la perte) vérifie son
    identité — jamais le trouveur : ce n'est pas son document."""
    if match.user_lost_id != user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Seul le propriétaire du document vérifie son identité.",
        )


@router.post("/{match_id}/verify", response_model=VerificationRead)
async def request_verification(
    match_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    match = await _get_match(db, match_id, current_user.id)
    if not match:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="Accès refusé à ce match"
        )
    _assert_owner(match, current_user.id)
    verif = await verification_service.request_verification(
        db, match_id, current_user.id, match_score=match.score
    )
    return verif


@router.post("/{match_id}/verify/selfie", response_model=VerificationRead)
async def submit_selfie(
    match_id: uuid.UUID,
    selfie: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    match = await _get_match(db, match_id, current_user.id)
    if not match:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="Accès refusé à ce match"
        )
    _assert_owner(match, current_user.id)
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


@router.post("/{match_id}/verify/doc_photo", response_model=VerificationRead)
async def submit_doc_photo(
    match_id: uuid.UUID,
    photo: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Photo du document (niveau 3 — vérification renforcée, revue admin)."""
    match = await _get_match(db, match_id, current_user.id)
    if not match:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="Accès refusé à ce match"
        )
    _assert_owner(match, current_user.id)
    verif = await verification_service.get_verification(db, match_id, current_user.id)
    if not verif:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Demande de vérification introuvable",
        )
    content = await photo.read()
    return await verification_service.submit_doc_photo(
        db, verif, content, photo.content_type or "image/jpeg"
    )


@router.post("/{match_id}/verify/answers", response_model=VerificationRead)
async def submit_control_answers(
    match_id: uuid.UUID,
    payload: ControlAnswers,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Questions de contrôle (preuve de propriété) — comparées aux infos du
    document trouvé. Anti-usurpation : seul le vrai titulaire connaît ces données.
    """
    match = await _get_match(db, match_id, current_user.id)
    if not match:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Match introuvable"
        )
    _assert_owner(match, current_user.id)
    decl = (
        await db.execute(
            select(Declaration).where(
                Declaration.id == match.declaration_found_id
            )
        )
    ).scalar_one_or_none()
    if not decl:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Document introuvable"
        )

    verif = await verification_service.request_verification(
        db, match_id, current_user.id, match_score=match.score
    )
    result = await verification_service.check_answers(
        db,
        verif,
        decl,
        current_user,
        full_name=payload.full_name,
        date_of_birth=payload.date_of_birth,
        document_number=payload.document_number,
    )
    if not result.passed:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=result.message
            or "Les informations ne correspondent pas au document. Vérifiez et réessayez.",
        )
    return verif


@router.get("/{match_id}/verify", response_model=VerificationRead | None)
async def get_verification_status(
    match_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Statut de la vérification du PROPRIÉTAIRE — lisible par les deux
    participants : le trouveur en a besoin pour savoir quand la conversation
    se débloque."""
    match = await _get_match(db, match_id, current_user.id)
    if not match:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="Accès refusé à ce match"
        )
    return await verification_service.get_verification(
        db, match_id, match.user_lost_id
    )


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
    # reported_id optionnel côté client → on le déduit de l'autre participant.
    if payload.reported_id is None:
        payload.reported_id = other_id
    elif payload.reported_id != other_id:
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
        if match.status != "confirmed":
            # Conversation indisponible : soit pas encore ouverte (identité non
            # vérifiée → "pending"), soit fermée/abandonnée ("closed"/"ignored").
            await ws.close(code=4004)
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
