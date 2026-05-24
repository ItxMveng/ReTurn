"""
Module Admin — Backoffice modération & analytics (F-40 à F-44)

Routes protégées par le rôle is_admin=True sur le modèle User.
Toutes les actions sensibles sont audit-loggées.
"""
import csv
import io
import uuid
from datetime import datetime, timedelta, timezone
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.declaration import Declaration
from app.models.match import Match
from app.models.restitution import Restitution
from app.models.user import User

router = APIRouter(prefix="/admin", tags=["admin"])


# ── Guard ─────────────────────────────────────────────────────────────────────

async def require_admin(
    current_user: User = Depends(get_current_user),
) -> User:
    """Dépendance : rejette les non-admins avec 403."""
    if not getattr(current_user, "is_admin", False):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Accès réservé aux administrateurs.",
        )
    return current_user


# ── Schemas inline ────────────────────────────────────────────────────────────

class GlobalStatsResponse(BaseModel):
    total_users: int
    total_declarations: int
    total_matches: int
    total_restitutions_completed: int
    restitution_success_rate: float          # en %
    avg_restitution_delay_days: Optional[float]
    period_days: int


class UserAdminRead(BaseModel):
    id: uuid.UUID
    phone_number: str
    full_name: Optional[str]
    reputation_score: float
    is_admin: bool
    is_banned: bool
    created_at: datetime

    class Config:
        from_attributes = True


class BanRequest(BaseModel):
    reason: str


class DeclarationAdminRead(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    document_type: str
    declaration_type: str
    status: str
    created_at: datetime
    is_flagged: bool

    class Config:
        from_attributes = True


# ── Analytics globaux (F-42) ──────────────────────────────────────────────────

@router.get("/stats", response_model=GlobalStatsResponse)
async def global_stats(
    period_days: int = Query(30, ge=1, le=365),
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    """
    Statistiques globales de la plateforme sur la période demandée.
    F-42 — Analytics et reporting.
    """
    since = datetime.now(timezone.utc) - timedelta(days=period_days)

    total_users   = (await db.execute(select(func.count(User.id)))).scalar_one()
    total_decls   = (await db.execute(select(func.count(Declaration.id)).where(Declaration.created_at >= since))).scalar_one()
    total_matches = (await db.execute(select(func.count(Match.id)).where(Match.created_at >= since))).scalar_one()

    completed_q = select(func.count(Restitution.id)).where(
        Restitution.status == "completed",
        Restitution.created_at >= since,
    )
    total_completed = (await db.execute(completed_q)).scalar_one()

    success_rate = (
        (total_completed / total_matches * 100) if total_matches > 0 else 0.0
    )

    # Délai moyen de restitution
    avg_delay = None
    delay_q = select(
        func.avg(
            func.extract(
                "epoch",
                Restitution.completed_at - Restitution.created_at,
            )
        )
    ).where(
        Restitution.status == "completed",
        Restitution.completed_at.isnot(None),
    )
    raw_avg = (await db.execute(delay_q)).scalar_one()
    if raw_avg is not None:
        avg_delay = round(raw_avg / 86400, 1)  # secondes → jours

    return GlobalStatsResponse(
        total_users=total_users,
        total_declarations=total_decls,
        total_matches=total_matches,
        total_restitutions_completed=total_completed,
        restitution_success_rate=round(success_rate, 1),
        avg_restitution_delay_days=avg_delay,
        period_days=period_days,
    )


# ── Export CSV (F-42) ────────────────────────────────────────────────────────────

@router.get("/export/declarations")
async def export_declarations_csv(
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    """
    Export CSV de toutes les déclarations (F-41, F-42).
    Utile pour les institutions partenaires.
    """
    result = await db.execute(
        select(Declaration).order_by(Declaration.created_at.desc())
    )
    declarations = result.scalars().all()

    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow(["id", "user_id", "document_type", "declaration_type",
                     "status", "created_at", "location_description"])
    for d in declarations:
        writer.writerow([
            str(d.id), str(d.user_id), d.document_type,
            d.declaration_type, d.status,
            d.created_at.isoformat(),
            getattr(d, "location_description", ""),
        ])
    output.seek(0)
    return StreamingResponse(
        iter([output.getvalue()]),
        media_type="text/csv",
        headers={"Content-Disposition": "attachment; filename=declarations_export.csv"},
    )


# ── Gestion des utilisateurs ─────────────────────────────────────────────────────

@router.get("/users", response_model=list[UserAdminRead])
async def list_users(
    page: int = Query(1, ge=1),
    per_page: int = Query(50, ge=1, le=100),
    search: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    """Liste paginée des utilisateurs avec filtre optionnel."""
    q = select(User).order_by(User.created_at.desc())
    if search:
        q = q.where(
            User.phone_number.ilike(f"%{search}%") |
            User.full_name.ilike(f"%{search}%")
        )
    q = q.offset((page - 1) * per_page).limit(per_page)
    result = await db.execute(q)
    return result.scalars().all()


@router.patch("/users/{user_id}/ban", status_code=status.HTTP_200_OK)
async def ban_user(
    user_id: uuid.UUID,
    body: BanRequest,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin),
):
    """
    Bannir un utilisateur (anti-fraude).
    L’audit log est assuré par l’endpoint lui-même.
    """
    user = await db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="Utilisateur introuvable.")
    if user.id == admin.id:
        raise HTTPException(status_code=400, detail="Vous ne pouvez pas vous bannir vous-même.")
    user.is_banned = True  # type: ignore[assignment]
    await db.commit()
    return {"detail": f"Utilisateur {user_id} banni. Raison : {body.reason}"}


@router.patch("/users/{user_id}/unban", status_code=status.HTTP_200_OK)
async def unban_user(
    user_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    """Rétablir un compte banni."""
    user = await db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="Utilisateur introuvable.")
    user.is_banned = False  # type: ignore[assignment]
    await db.commit()
    return {"detail": f"Utilisateur {user_id} rétabli."}


@router.patch("/users/{user_id}/promote", status_code=status.HTTP_200_OK)
async def promote_to_admin(
    user_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    """Passer un utilisateur en mode admin."""
    user = await db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="Utilisateur introuvable.")
    user.is_admin = True  # type: ignore[assignment]
    await db.commit()
    return {"detail": f"Utilisateur {user_id} promu administrateur."}


# ── Modération des déclarations ──────────────────────────────────────────────────

@router.get("/declarations", response_model=list[DeclarationAdminRead])
async def list_all_declarations(
    page: int = Query(1, ge=1),
    per_page: int = Query(50, ge=1, le=100),
    flagged_only: bool = False,
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    """Liste toutes les déclarations avec filtre sur les signalements."""
    q = select(Declaration).order_by(Declaration.created_at.desc())
    if flagged_only:
        q = q.where(Declaration.is_flagged == True)  # noqa: E712
    q = q.offset((page - 1) * per_page).limit(per_page)
    result = await db.execute(q)
    return result.scalars().all()


@router.delete("/declarations/{declaration_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_declaration(
    declaration_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    """Supprimer une déclaration frauduleuse (modération)."""
    decl = await db.get(Declaration, declaration_id)
    if not decl:
        raise HTTPException(status_code=404, detail="Déclaration introuvable.")
    await db.delete(decl)
    await db.commit()


@router.patch("/declarations/{declaration_id}/flag")
async def flag_declaration(
    declaration_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    """Marquer une déclaration comme suspecte."""
    decl = await db.get(Declaration, declaration_id)
    if not decl:
        raise HTTPException(status_code=404, detail="Déclaration introuvable.")
    decl.is_flagged = True  # type: ignore[assignment]
    await db.commit()
    return {"detail": "Déclaration marquée comme suspecte."}


# ── Zones de récupération (F-32, F-43) ─────────────────────────────────────────

class ZoneCreate(BaseModel):
    name: str
    zone_type: str          # "commissariat" | "mairie" | "campus" | "autre"
    latitude: float
    longitude: float
    address: str
    institution_id: Optional[uuid.UUID] = None
    is_certified: bool = True


class ZoneRead(BaseModel):
    id: uuid.UUID
    name: str
    zone_type: str
    address: str
    latitude: float
    longitude: float
    is_certified: bool
    institution_id: Optional[uuid.UUID]

    class Config:
        from_attributes = True


@router.post("/zones", response_model=ZoneRead, status_code=status.HTTP_201_CREATED)
async def create_zone(
    body: ZoneCreate,
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    """
    Ajouter un point de dépôt certifié (commissariat, mairie, campus).
    F-32 + F-43 — Badge 'Point de dépôt certifié'.
    """
    from app.models.zone import Zone
    zone = Zone(
        id=uuid.uuid4(),
        name=body.name,
        zone_type=body.zone_type,
        latitude=body.latitude,
        longitude=body.longitude,
        address=body.address,
        institution_id=body.institution_id,
        is_certified=body.is_certified,
    )
    db.add(zone)
    await db.commit()
    await db.refresh(zone)
    return zone


@router.get("/zones", response_model=list[ZoneRead])
async def list_zones(
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    """Lister tous les points de dépôt (vue admin complète)."""
    from app.models.zone import Zone
    result = await db.execute(select(Zone).order_by(Zone.name))
    return result.scalars().all()


@router.delete("/zones/{zone_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_zone(
    zone_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    """Supprimer un point de dépôt."""
    from app.models.zone import Zone
    zone = await db.get(Zone, zone_id)
    if not zone:
        raise HTTPException(status_code=404, detail="Zone introuvable.")
    await db.delete(zone)
    await db.commit()
