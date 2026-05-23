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
from app.schemas.match import MatchAction, MatchRead
from app.services.notification_service import (
    clear_notifications,
    get_pending_notifications,
)

router = APIRouter(prefix="/matches", tags=["matches"])


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
    return list(result.scalars().all())


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
    result = await db.execute(
        select(Match)
        .options(
            selectinload(Match.declaration_found),
            selectinload(Match.declaration_lost),
        )
        .where(
            Match.id == match_id,
            or_(
                Match.user_found_id == current_user.id,
                Match.user_lost_id == current_user.id,
            ),
        )
    )
    match = result.scalar_one_or_none()
    if not match:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Match introuvable")
    return match


@router.post("/{match_id}/action", response_model=MatchRead)
async def act_on_match(
    match_id: uuid.UUID,
    body: MatchAction,
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
            Match.id == match_id,
            or_(
                Match.user_found_id == current_user.id,
                Match.user_lost_id == current_user.id,
            ),
        )
    )
    match = result.scalar_one_or_none()
    if not match:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Match introuvable")
    if match.status not in ("pending",):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Ce match est déjà '{match.status}'",
        )
    match.status = body.action
    db.add(match)
    await db.flush()
    return match
