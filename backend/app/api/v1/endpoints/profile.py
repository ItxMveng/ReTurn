from fastapi import APIRouter, Depends, File, UploadFile
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.dependencies import get_current_user
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
