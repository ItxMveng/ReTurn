from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.declaration import Declaration
from app.models.user import User
from app.schemas.user import UserRead, UserUpdate
from app.services import storage_service

router = APIRouter(prefix="/profile", tags=["profile"])


@router.get("/", response_model=UserRead)
async def get_profile(current_user: User = Depends(get_current_user)):
    return current_user


@router.patch("/", response_model=UserRead)
async def update_profile(
    body: UserUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    update_data = body.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(current_user, field, value)
    db.add(current_user)
    await db.flush()
    return current_user


@router.patch("/avatar", response_model=UserRead)
async def update_avatar(
    avatar: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    await storage_service.ensure_bucket()
    content = await avatar.read()
    url = await storage_service.upload_photo(
        content,
        str(current_user.id),
        "avatar",
        avatar.content_type or "image/jpeg",
    )
    current_user.avatar_url = url
    db.add(current_user)
    await db.flush()
    return current_user


@router.delete("/", status_code=status.HTTP_204_NO_CONTENT)
async def delete_account(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    RGPD (F-04) — Permanent account deletion.
    Cascades to declarations, matches, messages via DB ON DELETE CASCADE.
    Also purges avatar from object storage.
    """
    # Delete avatar from MinIO if present
    if current_user.avatar_url:
        try:
            await storage_service.delete_photo(current_user.avatar_url)
        except Exception:
            pass  # non-blocking: storage cleanup best-effort

    # Delete all declaration photos from MinIO
    result = await db.execute(
        select(Declaration).where(Declaration.user_id == current_user.id)
    )
    for decl in result.scalars().all():
        for url in decl.photo_urls:
            try:
                await storage_service.delete_photo(url)
            except Exception:
                pass

    await db.delete(current_user)
    # DB cascade handles declarations, matches, messages
