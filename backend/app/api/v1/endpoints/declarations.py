import uuid
from datetime import date as DateType

from fastapi import APIRouter, Depends, File, Form, HTTPException, Query, UploadFile, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.schemas.declaration import (
    DeclarationCreate,
    DeclarationRead,
    DeclarationUpdate,
    DOCUMENT_TYPES,
)
from app.core.redis_client import get_redis
from app.services import declaration_service, storage_service
from app.services.matching_service import run_matching

router = APIRouter(prefix="/declarations", tags=["declarations"])

ACTIVE_DECLARATIONS_LIMIT = 3  # F-15 anti-fraud


@router.get("/document-types", response_model=list[str])
async def get_document_types():
    return DOCUMENT_TYPES


@router.post("/", response_model=DeclarationRead, status_code=status.HTTP_201_CREATED)
async def create_declaration(
    declaration_type: str = Form(...),
    document_type: str = Form(...),
    document_number: str | None = Form(None),
    owner_name: str | None = Form(None),
    description: str | None = Form(None),
    latitude: float | None = Form(None),
    longitude: float | None = Form(None),
    location_description: str | None = Form(None),
    event_date: DateType | None = Form(None),
    photos: list[UploadFile] = File(default=[]),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
    redis=Depends(get_redis),
):
    # F-15: Limit to 3 active declarations simultaneously
    active_count = await declaration_service.count_active(db, current_user.id)
    if active_count >= ACTIVE_DECLARATIONS_LIMIT:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail=f"Vous ne pouvez pas avoir plus de {ACTIVE_DECLARATIONS_LIMIT} déclarations actives simultanément.",
        )

    data = DeclarationCreate(
        declaration_type=declaration_type,
        document_type=document_type,
        document_number=document_number,
        owner_name=owner_name,
        description=description,
        latitude=latitude,
        longitude=longitude,
        location_description=location_description,
        event_date=event_date,
    )
    await storage_service.ensure_bucket()
    decl = await declaration_service.create_declaration(db, current_user, data, photos)
    await run_matching(db, redis, decl)
    return decl


@router.get("/", response_model=list[DeclarationRead])
async def list_my_declarations(
    limit: int = Query(20, le=100),
    cursor: str | None = Query(None, description="ISO datetime cursor for pagination (created_at of last item)"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Cursor-based pagination. Pass `cursor` = created_at of last item received."""
    return await declaration_service.list_declarations_cursor(
        db, current_user.id, limit=limit, cursor=cursor
    )


@router.get("/{declaration_id}", response_model=DeclarationRead)
async def get_declaration(
    declaration_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    decl = await declaration_service.get_declaration(db, declaration_id, current_user.id)
    if not decl:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Déclaration introuvable")
    return decl


@router.patch("/{declaration_id}", response_model=DeclarationRead)
async def update_declaration(
    declaration_id: uuid.UUID,
    body: DeclarationUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    decl = await declaration_service.get_declaration(db, declaration_id, current_user.id)
    if not decl:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Déclaration introuvable")
    return await declaration_service.update_declaration(db, decl, body)


@router.delete("/{declaration_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_declaration(
    declaration_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    decl = await declaration_service.get_declaration(db, declaration_id, current_user.id)
    if not decl:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Déclaration introuvable")
    await declaration_service.delete_declaration(db, decl)


@router.post("/{declaration_id}/photos", response_model=DeclarationRead)
async def add_photo(
    declaration_id: uuid.UUID,
    photo: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    decl = await declaration_service.get_declaration(db, declaration_id, current_user.id)
    if not decl:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Déclaration introuvable")
    if len(decl.photo_urls) >= 3:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Maximum 3 photos par déclaration",
        )
    await storage_service.ensure_bucket()
    content = await photo.read()
    url = await storage_service.upload_photo(
        content, str(current_user.id), str(declaration_id),
        photo.content_type or "image/jpeg",
    )
    decl.photo_urls = decl.photo_urls + [url]
    db.add(decl)
    await db.flush()
    return decl
