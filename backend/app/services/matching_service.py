import uuid

from redis.asyncio import Redis
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.declaration import Declaration
from app.models.match import Match
from app.models.user import User
from app.services.notification_service import push_match_notification


def _compute_score(new: Declaration, candidate: Declaration) -> float:
    """
    Returns a match confidence score between 0.0 and 1.0.
    0.0 means "definitely not a match" and will be excluded.
    """
    # Different doc numbers = hard no
    if new.document_number and candidate.document_number:
        if new.document_number.upper().strip() != candidate.document_number.upper().strip():
            return 0.0
        score = 1.0
    else:
        # At least same document_type
        score = 0.5

    # Owner name bonus
    if new.owner_name and candidate.owner_name:
        n1 = new.owner_name.upper().strip()
        n2 = candidate.owner_name.upper().strip()
        if n1 == n2:
            score = min(1.0, score + 0.4)
        elif n1 in n2 or n2 in n1:
            score = min(1.0, score + 0.2)

    return score


async def _match_already_exists(
    db: AsyncSession,
    found_id: uuid.UUID,
    lost_id: uuid.UUID,
) -> bool:
    result = await db.execute(
        select(Match).where(
            Match.declaration_found_id == found_id,
            Match.declaration_lost_id == lost_id,
        )
    )
    return result.scalar_one_or_none() is not None


async def run_matching(
    db: AsyncSession,
    redis: Redis,
    new_declaration: Declaration,
) -> list[Match]:
    opposite_type = "lost" if new_declaration.declaration_type == "found" else "found"

    result = await db.execute(
        select(Declaration).where(
            Declaration.declaration_type == opposite_type,
            Declaration.document_type == new_declaration.document_type,
            Declaration.status == "active",
            Declaration.user_id != new_declaration.user_id,
        )
    )
    candidates = list(result.scalars().all())

    created_matches: list[Match] = []

    for candidate in candidates:
        score = _compute_score(new_declaration, candidate)
        if score < 0.4:
            continue

        found_id = (
            new_declaration.id
            if new_declaration.declaration_type == "found"
            else candidate.id
        )
        lost_id = (
            new_declaration.id
            if new_declaration.declaration_type == "lost"
            else candidate.id
        )

        if await _match_already_exists(db, found_id, lost_id):
            continue

        user_found_id = (
            new_declaration.user_id
            if new_declaration.declaration_type == "found"
            else candidate.user_id
        )
        user_lost_id = (
            new_declaration.user_id
            if new_declaration.declaration_type == "lost"
            else candidate.user_id
        )

        match = Match(
            declaration_found_id=found_id,
            declaration_lost_id=lost_id,
            user_found_id=user_found_id,
            user_lost_id=user_lost_id,
            score=score,
        )
        db.add(match)
        await db.flush()

        # Fetch FCM tokens for both users
        res_found = await db.execute(select(User).where(User.id == user_found_id))
        user_found = res_found.scalar_one_or_none()
        res_lost = await db.execute(select(User).where(User.id == user_lost_id))
        user_lost = res_lost.scalar_one_or_none()

        await push_match_notification(
            redis, user_found_id, match.id, score, new_declaration.document_type,
            fcm_token=user_found.fcm_token if user_found else None,
        )
        await push_match_notification(
            redis, user_lost_id, match.id, score, new_declaration.document_type,
            fcm_token=user_lost.fcm_token if user_lost else None,
        )

        created_matches.append(match)

    return created_matches
