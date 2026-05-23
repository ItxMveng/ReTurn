import uuid
from datetime import datetime

from fastapi import UploadFile
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.declaration import Declaration
from app.models.user import User
from app.schemas.declaration import DeclarationCreate, DeclarationUpdate
from app.services import storage_service


async def count_active(db: AsyncSession, user_id: uuid.UUID) -> int:
    """Return the number of active declarations for a user (used for F-15 limit)."""
    result = await db.execute(
        select(func.count()).where(
            Declaration.user_id == user_id,
            Declaration.status == "active",
        )
    )
    return result.scalar_one()


async def create_declaration(
    db: AsyncSession,
    user: User,
    data: DeclarationCreate,
    photos: list[UploadFile],
) -> Declaration:
    declaration_id = str(uuid.uuid4())
    photo_urls: list[str] = []

    for photo in photos[:3]:
        content = await photo.read()
        if content:
            url = await storage_service.upload_photo(
                content,
                str(user.id),
                declaration_id,
                photo.content_type or "image/jpeg",
            )
            photo_urls.append(url)

    decl = Declaration(
        id=uuid.UUID(declaration_id),
        user_id=user.id,
        photo_urls=photo_urls,
        **data.model_dump(),
    )
    db.add(decl)
    await db.flush()
    return decl


async def list_declarations_cursor(
    db: AsyncSession,
    user_id: uuid.UUID,
    limit: int = 20,
    cursor: str | None = None,
) -> list[Declaration]:
    """
    Cursor-based pagination on created_at (ISO 8601 string).
    Returns declarations created BEFORE the cursor datetime, newest first.
    """
    query = (
        select(Declaration)
        .where(Declaration.user_id == user_id)
        .order_by(Declaration.created_at.desc())
        .limit(limit)
    )
    if cursor:
        try:
            cursor_dt = datetime.fromisoformat(cursor)
            query = query.where(Declaration.created_at < cursor_dt)
        except ValueError:
            pass  # invalid cursor → ignore, return first page
    result = await db.execute(query)
    return list(result.scalars().all())


async def get_declaration(
    db: AsyncSession, declaration_id: uuid.UUID, user_id: uuid.UUID
) -> Declaration | None:
    result = await db.execute(
        select(Declaration).where(
            Declaration.id == declaration_id,
            Declaration.user_id == user_id,
        )
    )
    return result.scalar_one_or_none()


async def update_declaration(
    db: AsyncSession,
    declaration: Declaration,
    data: DeclarationUpdate,
) -> Declaration:
    for field, value in data.model_dump(exclude_none=True).items():
        setattr(declaration, field, value)
    db.add(declaration)
    await db.flush()
    return declaration


async def delete_declaration(db: AsyncSession, declaration: Declaration) -> None:
    for url in declaration.photo_urls:
        await storage_service.delete_photo(url)
    await db.delete(declaration)
    await db.flush()
