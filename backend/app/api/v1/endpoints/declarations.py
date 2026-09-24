import json
import uuid
from datetime import date as DateType

from fastapi import APIRouter, Depends, File, Form, HTTPException, Query, UploadFile, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.countries import normalize_country_code
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
from app.services import config_service, declaration_service, storage_service
from app.services.matching_service import run_matching

router = APIRouter(prefix="/declarations", tags=["declarations"])

ACTIVE_DECLARATIONS_LIMIT = 3  # F-15 anti-fraud — défaut, surchargé par app_config


@router.get("/document-types", response_model=list[str])
async def get_document_types():
    return DOCUMENT_TYPES


@router.get("/limits")
async def get_declaration_limits(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Compteur de déclarations actives + limite dynamique (chip UI mobile)."""
    limit = int(await config_service.get_value(db, "active_declarations_limit"))
    active_count = await declaration_service.count_active(db, current_user.id)
    return {"active_count": active_count, "limit": limit}


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
    country_code: str | None = Form(None, description="ISO 3166-1 alpha-2 ; défaut : pays du profil"),
    event_date: DateType | None = Form(None),
    photos: list[UploadFile] = File(default=[]),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
    redis=Depends(get_redis),
):
    # F-15: limite de déclarations actives simultanées (configurable via admin)
    limit = int(await config_service.get_value(db, "active_declarations_limit"))
    active_count = await declaration_service.count_active(db, current_user.id)
    if active_count >= limit:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail=f"Vous ne pouvez pas avoir plus de {limit} déclarations actives simultanément.",
        )

    try:
        data = DeclarationCreate(
            declaration_type=declaration_type,
            document_type=document_type,
            document_number=document_number,
            owner_name=owner_name,
            description=description,
            latitude=latitude,
            longitude=longitude,
            location_description=location_description,
            country_code=normalize_country_code(country_code) or current_user.country_code,
            event_date=event_date,
        )
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=str(exc)
        )
    await storage_service.ensure_bucket()
    decl = await declaration_service.create_declaration(db, current_user, data, photos)
    await run_matching(db, redis, decl)
    return decl


MAX_GROUP_ITEMS = 5  # taille maximale d'un dossier multi-documents


@router.post("/batch", response_model=list[DeclarationRead], status_code=status.HTTP_201_CREATED)
async def create_declaration_batch(
    declaration_type: str = Form(...),
    items: str = Form(..., description='JSON: [{"document_type", "owner_name", "document_number"}]'),
    description: str | None = Form(None),
    latitude: float | None = Form(None),
    longitude: float | None = Form(None),
    location_description: str | None = Form(None),
    country_code: str | None = Form(None, description="ISO 3166-1 alpha-2 ; défaut : pays du profil"),
    event_date: DateType | None = Form(None),
    photo_map: str | None = Form(
        None, description="JSON list[int] : index du document pour chaque photo (une photo par document)."
    ),
    photos: list[UploadFile] = File(default=[]),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
    redis=Depends(get_redis),
):
    """Dossier multi-documents : déclare plusieurs documents trouvés/perdus
    en une seule fois (ex. portefeuille avec CNI + permis + carte bancaire).

    Chaque document devient une déclaration à part entière (matching
    individuel) ; le dossier entier compte pour UNE déclaration dans la
    limite F-15.
    """
    try:
        raw_items = json.loads(items)
        assert isinstance(raw_items, list)
    except (json.JSONDecodeError, AssertionError):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Le champ items doit être une liste JSON de documents.",
        )
    if not 1 <= len(raw_items) <= MAX_GROUP_ITEMS:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"Un dossier contient entre 1 et {MAX_GROUP_ITEMS} documents.",
        )

    try:
        group_country = normalize_country_code(country_code) or current_user.country_code
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=str(exc)
        )

    # Validation de chaque document via le schéma habituel (types, etc.).
    parsed: list[DeclarationCreate] = []
    for i, raw in enumerate(raw_items, start=1):
        if not isinstance(raw, dict):
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=f"Document n°{i} invalide.",
            )
        try:
            parsed.append(DeclarationCreate(
                declaration_type=declaration_type,
                document_type=str(raw.get("document_type", "")),
                document_number=(str(raw["document_number"]).strip() or None)
                if raw.get("document_number") else None,
                owner_name=(str(raw["owner_name"]).strip() or None)
                if raw.get("owner_name") else None,
                description=description,
                latitude=latitude,
                longitude=longitude,
                location_description=location_description,
                country_code=group_country,
                event_date=event_date,
            ))
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=f"Type de document invalide pour le document n°{i}.",
            )

    # F-15 : un dossier occupe UN seul emplacement de déclaration active.
    limit = int(await config_service.get_value(db, "active_declarations_limit"))
    active_count = await declaration_service.count_active(db, current_user.id)
    if active_count >= limit:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail=f"Vous ne pouvez pas avoir plus de {limit} déclarations actives simultanément.",
        )

    # Mapping optionnel photo → document (une photo propre par document).
    parsed_photo_map: list[int] | None = None
    if photo_map:
        try:
            raw_map = json.loads(photo_map)
            assert isinstance(raw_map, list) and all(
                isinstance(x, int) for x in raw_map
            )
            parsed_photo_map = raw_map
        except (json.JSONDecodeError, AssertionError):
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="photo_map doit être une liste JSON d'entiers.",
            )

    await storage_service.ensure_bucket()
    declarations = await declaration_service.create_declarations_group(
        db, current_user, parsed, photos, photo_map=parsed_photo_map
    )
    for decl in declarations:
        await run_matching(db, redis, decl)
    return declarations


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
