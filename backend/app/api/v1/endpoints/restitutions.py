import uuid

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.schemas.restitution import RestitutionRating, RestitutionRead, RestitutionUpdate
from app.services import restitution_service, storage_service

router = APIRouter(prefix="/restitutions", tags=["restitutions"])


@router.get("/", response_model=list[RestitutionRead])
async def list_my_restitutions(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Historique des restitutions de l'utilisateur (F-35)."""
    return await restitution_service.list_user_restitutions(db, current_user.id)


@router.get("/by-match/{match_id}", response_model=RestitutionRead | None)
async def get_restitution_by_match(
    match_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await restitution_service.get_restitution_by_match(
        db, match_id, current_user.id
    )


@router.post("/{restitution_id}/confirm", response_model=RestitutionRead)
async def confirm_restitution(
    restitution_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Double validation (F-33) : confirme la remise pour votre compte."""
    restitution = await restitution_service.get_restitution(
        db, restitution_id, current_user.id
    )
    if not restitution:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Restitution introuvable",
        )
    return await restitution_service.confirm_restitution(
        db, restitution, current_user.id
    )


@router.get("/{restitution_id}", response_model=RestitutionRead)
async def get_restitution(
    restitution_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    restitution = await restitution_service.get_restitution(
        db, restitution_id, current_user.id
    )
    if not restitution:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Restitution introuvable",
        )
    return restitution


@router.patch("/{restitution_id}", response_model=RestitutionRead)
async def update_restitution(
    restitution_id: uuid.UUID,
    body: RestitutionUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Update meeting point or status."""
    restitution = await restitution_service.get_restitution(
        db, restitution_id, current_user.id
    )
    if not restitution:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Restitution introuvable",
        )
    return await restitution_service.update_restitution(db, restitution, body)


@router.post("/{restitution_id}/photos", response_model=RestitutionRead)
async def upload_proof_photo(
    restitution_id: uuid.UUID,
    photo: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Upload a proof photo for the physical handoff."""
    restitution = await restitution_service.get_restitution(
        db, restitution_id, current_user.id
    )
    if not restitution:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Restitution introuvable",
        )
    await storage_service.ensure_bucket()
    content = await photo.read()
    url = await storage_service.upload_photo(
        content,
        str(current_user.id),
        f"restitution_{restitution_id}",
        photo.content_type or "image/jpeg",
    )
    return await restitution_service.add_proof_photo(db, restitution, url)


@router.post("/{restitution_id}/rate", response_model=RestitutionRead)
async def rate_restitution(
    restitution_id: uuid.UUID,
    body: RestitutionRating,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Submit a post-restitution rating (1-5 stars).
    Automatically updates the other party’s reputation score (F-05).
    """
    restitution = await restitution_service.get_restitution(
        db, restitution_id, current_user.id
    )
    if not restitution:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Restitution introuvable",
        )
    if restitution.status != "completed":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="La restitution doit être complétée avant de noter.",
        )
    return await restitution_service.submit_rating(
        db, restitution, current_user.id, body.rating, comment=body.comment
    )
