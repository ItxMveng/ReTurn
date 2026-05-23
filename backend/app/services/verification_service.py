import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.verification import IdentityVerification
from app.services.storage_service import ensure_bucket, upload_photo


async def request_verification(
    db: AsyncSession,
    match_id: uuid.UUID,
    user_id: uuid.UUID,
) -> IdentityVerification:
    result = await db.execute(
        select(IdentityVerification).where(
            IdentityVerification.match_id == match_id,
            IdentityVerification.user_id == user_id,
        )
    )
    existing = result.scalar_one_or_none()
    if existing:
        return existing

    verif = IdentityVerification(match_id=match_id, user_id=user_id)
    db.add(verif)
    await db.flush()
    return verif


async def submit_selfie(
    db: AsyncSession,
    verif: IdentityVerification,
    selfie_bytes: bytes,
    content_type: str,
) -> IdentityVerification:
    await ensure_bucket()
    url = await upload_photo(
        selfie_bytes,
        str(verif.user_id),
        f"verif_{verif.match_id}",
        content_type,
    )
    verif.selfie_url = url
    verif.status = "approved"
    db.add(verif)
    await db.flush()
    return verif


async def get_verification(
    db: AsyncSession,
    match_id: uuid.UUID,
    user_id: uuid.UUID,
) -> IdentityVerification | None:
    result = await db.execute(
        select(IdentityVerification).where(
            IdentityVerification.match_id == match_id,
            IdentityVerification.user_id == user_id,
        )
    )
    return result.scalar_one_or_none()
