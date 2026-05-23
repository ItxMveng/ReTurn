"""Restitution service — handles the full handoff lifecycle (F-33).

Flow:
  1. Both parties confirm the Match → Match.status = "confirmed"
  2. create_restitution() is called automatically → Restitution.status = "pending"
  3. Parties agree on meeting point → update_restitution()
  4. Physical handoff happens, proof photo uploaded → add_proof_photo()
  5. Either party marks as completed → update_restitution(status="completed")
  6. Each party submits a rating → submit_rating() → updates score_reputation (F-05)
"""
import uuid
from datetime import datetime, timezone
from typing import TYPE_CHECKING

from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.match import Match
from app.models.restitution import Restitution
from app.models.user import User
from app.schemas.restitution import RestitutionUpdate

_REPUTATION_WEIGHT = 0.3   # New rating blended in with 30% weight
_REPUTATION_MIN = 0.0
_REPUTATION_MAX = 10.0


async def create_restitution(
    db: AsyncSession,
    match_id: uuid.UUID,
) -> Restitution:
    """Create a Restitution row when both parties have confirmed the Match."""
    # Idempotent: return existing if already created
    existing = await db.execute(
        select(Restitution).where(Restitution.match_id == match_id)
    )
    if restitution := existing.scalar_one_or_none():
        return restitution

    restitution = Restitution(match_id=match_id)
    db.add(restitution)
    await db.flush()
    return restitution


async def get_restitution(
    db: AsyncSession,
    restitution_id: uuid.UUID,
    user_id: uuid.UUID,
) -> Restitution | None:
    """Return the restitution only if the caller is a participant of the linked match."""
    result = await db.execute(
        select(Restitution)
        .join(Match, Match.id == Restitution.match_id)
        .where(
            Restitution.id == restitution_id,
            or_(
                Match.user_found_id == user_id,
                Match.user_lost_id == user_id,
            ),
        )
    )
    return result.scalar_one_or_none()


async def update_restitution(
    db: AsyncSession,
    restitution: Restitution,
    data: RestitutionUpdate,
) -> Restitution:
    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(restitution, field, value)
    if data.status == "completed" and not restitution.completed_at:
        restitution.completed_at = datetime.now(timezone.utc)
    db.add(restitution)
    await db.flush()
    return restitution


async def add_proof_photo(
    db: AsyncSession,
    restitution: Restitution,
    photo_url: str,
) -> Restitution:
    restitution.proof_photos = restitution.proof_photos + [photo_url]
    db.add(restitution)
    await db.flush()
    return restitution


async def submit_rating(
    db: AsyncSession,
    restitution: Restitution,
    rater_id: uuid.UUID,
    rating: int,
) -> Restitution:
    """
    Submit a rating and update the OTHER party’s reputation score.
    Uses exponential moving average: new_score = old_score * (1 - w) + rating*2 * w
    Rating is 1-5 stars, mapped to 2-10 scale to match score_reputation range (0-10).
    """
    result = await db.execute(
        select(Match)
        .where(Match.id == restitution.match_id)
    )
    match = result.scalar_one_or_none()
    if not match:
        return restitution

    is_owner = match.user_lost_id == rater_id
    is_finder = match.user_found_id == rater_id

    if is_owner and restitution.rating_by_owner is None:
        restitution.rating_by_owner = rating
        # Owner rates the finder
        rated_user_id = match.user_found_id
    elif is_finder and restitution.rating_by_finder is None:
        restitution.rating_by_finder = rating
        # Finder rates the owner
        rated_user_id = match.user_lost_id
    else:
        return restitution  # Already rated or wrong role

    # Update reputation: map 1-5 stars to 2-10 points, then blend
    res_user = await db.execute(select(User).where(User.id == rated_user_id))
    rated_user = res_user.scalar_one_or_none()
    if rated_user:
        score_contribution = rating * 2.0  # 1★ -> 2.0 pts, 5★ -> 10.0 pts
        new_rep = rated_user.score_reputation * (1 - _REPUTATION_WEIGHT) + score_contribution * _REPUTATION_WEIGHT
        rated_user.score_reputation = round(
            max(_REPUTATION_MIN, min(_REPUTATION_MAX, new_rep)), 2
        )
        db.add(rated_user)

    db.add(restitution)
    await db.flush()
    return restitution
