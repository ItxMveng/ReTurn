import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.core.redis_client import get_redis
from app.models.match import Match
from app.models.user import User
from app.schemas.match import MatchAction, MatchConfirmResponse, MatchRead
from app.services import restitution_service
from app.services.matching_service import release_declarations
from app.services.notification_service import (
    clear_notifications,
    get_pending_notifications,
)

router = APIRouter(prefix="/matches", tags=["matches"])


async def _attach_other_user(
    db: AsyncSession, match: Match, current_user_id: uuid.UUID
) -> Match:
    """Renseigne le nom/avatar de l'AUTRE participant (jamais l'utilisateur courant)."""
    other_id = (
        match.user_lost_id
        if match.user_found_id == current_user_id
        else match.user_found_id
    )
    other = (
        await db.execute(select(User).where(User.id == other_id))
    ).scalar_one_or_none()
    if other is not None:
        match.other_user_name = (
            (other.full_name or "").strip() or "Utilisateur"
        )
        match.other_user_avatar = other.avatar_url
    return match


@router.get("/", response_model=list[MatchRead])
async def list_my_matches(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(Match)
        .options(
            selectinload(Match.declaration_found),
            selectinload(Match.declaration_lost),
        )
        .where(
            or_(
                Match.user_found_id == current_user.id,
                Match.user_lost_id == current_user.id,
            ),
            Match.status != "ignored",
        )
        .order_by(Match.score.desc(), Match.created_at.desc())
    )
    matches = list(result.scalars().all())
    for m in matches:
        await _attach_other_user(db, m, current_user.id)
    return matches


@router.get("/notifications")
async def get_notifications(
    current_user: User = Depends(get_current_user),
    redis=Depends(get_redis),
):
    notifications = await get_pending_notifications(redis, current_user.id)
    return {"count": len(notifications), "notifications": notifications}


@router.delete("/notifications", status_code=status.HTTP_204_NO_CONTENT)
async def clear_my_notifications(
    current_user: User = Depends(get_current_user),
    redis=Depends(get_redis),
):
    await clear_notifications(redis, current_user.id)


@router.get("/{match_id}", response_model=MatchRead)
async def get_match(
    match_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    match = await _get_match_or_404(db, match_id, current_user.id)
    await _attach_other_user(db, match, current_user.id)
    return match


@router.post("/{match_id}/action", response_model=MatchConfirmResponse)
async def act_on_match(
    match_id: uuid.UUID,
    body: MatchAction,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    match = await _get_match_or_404(db, match_id, current_user.id)

    if match.status not in ("pending", "confirmed"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Ce match est déjà '{match.status}'",
        )

    if body.action == "ignored":
        match.status = "ignored"
        db.add(match)
        await db.flush()
        # Rollback : les déclarations redeviennent "active" si aucun autre
        # match ouvert ne les référence (cohérence avec le matching).
        await release_declarations(db, match)
        return MatchConfirmResponse(
            match_id=match.id,
            accepted_by_owner=match.accepted_by_owner,
            accepted_by_finder=match.accepted_by_finder,
            both_confirmed=False,
        )

    # action == "confirmed": track which side accepted
    is_owner = match.user_lost_id == current_user.id
    is_finder = match.user_found_id == current_user.id

    if is_owner:
        match.accepted_by_owner = True
    elif is_finder:
        match.accepted_by_finder = True
    else:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Accès refusé")

    both_confirmed = match.accepted_by_owner and match.accepted_by_finder
    if both_confirmed:
        match.status = "confirmed"

    db.add(match)
    await db.flush()

    restitution_id: uuid.UUID | None = None
    if both_confirmed:
        restitution = await restitution_service.create_restitution(db, match.id)
        restitution_id = restitution.id

    return MatchConfirmResponse(
        match_id=match.id,
        accepted_by_owner=match.accepted_by_owner,
        accepted_by_finder=match.accepted_by_finder,
        both_confirmed=both_confirmed,
        restitution_id=restitution_id,
    )


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

async def _get_match_or_404(
    db: AsyncSession,
    match_id: uuid.UUID,
    user_id: uuid.UUID,
) -> Match:
    result = await db.execute(
        select(Match)
        .options(
            selectinload(Match.declaration_found),
            selectinload(Match.declaration_lost),
        )
        .where(
            Match.id == match_id,
            or_(
                Match.user_found_id == user_id,
                Match.user_lost_id == user_id,
            ),
        )
    )
    match = result.scalar_one_or_none()
    if not match:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Match introuvable",
        )
    return match
