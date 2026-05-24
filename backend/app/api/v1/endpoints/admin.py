"""
Module Admin — Backoffice modération & analytics (F-40 à F-44)

Routes protégées par le rôle is_admin=True sur le modèle User.
Toutes les actions sensibles sont audit-loggées via _audit().

Routes disponibles :
  GET  /admin/stats                          — KPIs globaux (F-42)
  GET  /admin/stats/chart                    — Séries temporelles pour graphiques
  GET  /admin/export/declarations            — Export CSV (F-41)
  GET  /admin/users                          — Liste paginée + filtre
  PATCH /admin/users/{id}/ban                — Bannir
  PATCH /admin/users/{id}/unban              — Rétablir
  PATCH /admin/users/{id}/promote            — Promouvoir admin
  GET  /admin/declarations                   — Toutes déclarations (filtre flagged)
  DELETE /admin/declarations/{id}            — Supprimer (modération)
  PATCH /admin/declarations/{id}/flag        — Marquer suspect
  POST /admin/declarations/bulk              — Import lot CSV (F-41)
  GET  /admin/matches                        — Tous les matchs (F-40 dashboard)
  GET  /admin/restitutions                   — Toutes les restitutions
  GET  /admin/zones                          — Lister zones
  POST /admin/zones                          — Créer zone certifiée (F-32, F-43)
  PATCH /admin/zones/{id}                    — Modifier zone
  DELETE /admin/zones/{id}                   — Supprimer zone
  GET  /admin/audit-logs                     — Historique des actions admin (§11.1)
"""
import csv
import io
import uuid
from datetime import datetime, date, timedelta, timezone
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, Request, UploadFile, File, status
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.audit_log import AuditLog
from app.models.declaration import Declaration
from app.models.match import Match
from app.models.restitution import Restitution
from app.models.user import User
from app.models.zone import Zone

router = APIRouter(prefix="/admin", tags=["admin"])


# ─────────────────────────────────────────────────────────────────────────────
# Guard — require_admin
# ─────────────────────────────────────────────────────────────────────────────

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


# ─────────────────────────────────────────────────────────────────────────────
# Helper — écriture audit log
# ─────────────────────────────────────────────────────────────────────────────

async def _audit(
    db: AsyncSession,
    admin: User,
    action_type: str,
    target_type: Optional[str] = None,
    target_id: Optional[str] = None,
    ip_address: Optional[str] = None,
    extra: Optional[dict] = None,
) -> None:
    """Enregistre une action admin dans la table audit_logs (CDC §11.1)."""
    log = AuditLog(
        id=uuid.uuid4(),
        admin_id=admin.id,
        action_type=action_type,
        target_type=target_type,
        target_id=str(target_id) if target_id else None,
        ip_address=ip_address,
        extra=extra or {},
    )
    db.add(log)
    # flush pour persister dans la même transaction que l'action principale
    await db.flush()


def _get_ip(request: Optional[Request]) -> Optional[str]:
    """Extrait l'IP réelle du client (derrière Nginx)."""
    if request is None:
        return None
    forwarded = request.headers.get("X-Forwarded-For")
    if forwarded:
        return forwarded.split(",")[0].strip()
    return request.client.host if request.client else None


# ─────────────────────────────────────────────────────────────────────────────
# Schemas
# ─────────────────────────────────────────────────────────────────────────────

class GlobalStatsResponse(BaseModel):
    total_users: int
    total_declarations: int
    total_matches: int
    total_restitutions_completed: int
    restitution_success_rate: float
    avg_restitution_delay_days: Optional[float]
    period_days: int


class ChartDataPoint(BaseModel):
    date: str          # YYYY-MM-DD
    declarations: int
    matches: int
    restitutions: int


class UserAdminRead(BaseModel):
    id: uuid.UUID
    phone_number: str
    full_name: Optional[str]
    score_reputation: float
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


class MatchAdminRead(BaseModel):
    id: uuid.UUID
    declaration_found_id: uuid.UUID
    declaration_lost_id: uuid.UUID
    user_found_id: uuid.UUID
    user_lost_id: uuid.UUID
    score: float
    status: str
    confirmed_by_owner: bool
    confirmed_by_finder: bool
    created_at: datetime

    class Config:
        from_attributes = True


class RestitutionAdminRead(BaseModel):
    id: uuid.UUID
    match_id: uuid.UUID
    status: str
    meeting_location: Optional[str]
    rating_by_owner: Optional[int]
    rating_by_finder: Optional[int]
    completed_at: Optional[datetime]
    created_at: datetime

    class Config:
        from_attributes = True


class ZoneCreate(BaseModel):
    name: str
    zone_type: str
    latitude: float
    longitude: float
    address: str
    institution_id: Optional[uuid.UUID] = None
    is_certified: bool = True


class ZoneUpdate(BaseModel):
    name: Optional[str] = None
    zone_type: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    address: Optional[str] = None
    is_certified: Optional[bool] = None
    institution_id: Optional[uuid.UUID] = None


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


class AuditLogRead(BaseModel):
    id: uuid.UUID
    admin_id: Optional[uuid.UUID]
    action_type: str
    target_type: Optional[str]
    target_id: Optional[str]
    ip_address: Optional[str]
    extra: Optional[dict]
    created_at: datetime

    class Config:
        from_attributes = True


# ─────────────────────────────────────────────────────────────────────────────
# Analytics globaux (F-42)
# ─────────────────────────────────────────────────────────────────────────────

@router.get("/stats", response_model=GlobalStatsResponse)
async def global_stats(
    period_days: int = Query(30, ge=1, le=365),
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    """
    KPIs globaux de la plateforme sur la période demandée.
    F-42 — Analytics et reporting.
    """
    since = datetime.now(timezone.utc) - timedelta(days=period_days)

    total_users   = (await db.execute(select(func.count(User.id)))).scalar_one()
    total_decls   = (await db.execute(
        select(func.count(Declaration.id)).where(Declaration.created_at >= since)
    )).scalar_one()
    total_matches = (await db.execute(
        select(func.count(Match.id)).where(Match.created_at >= since)
    )).scalar_one()
    total_completed = (await db.execute(
        select(func.count(Restitution.id)).where(
            Restitution.status == "completed",
            Restitution.created_at >= since,
        )
    )).scalar_one()

    success_rate = (total_completed / total_matches * 100) if total_matches > 0 else 0.0

    avg_delay = None
    raw_avg = (await db.execute(
        select(
            func.avg(
                func.extract("epoch", Restitution.completed_at - Restitution.created_at)
            )
        ).where(
            Restitution.status == "completed",
            Restitution.completed_at.isnot(None),
        )
    )).scalar_one()
    if raw_avg is not None:
        avg_delay = round(raw_avg / 86400, 1)

    return GlobalStatsResponse(
        total_users=total_users,
        total_declarations=total_decls,
        total_matches=total_matches,
        total_restitutions_completed=total_completed,
        restitution_success_rate=round(success_rate, 1),
        avg_restitution_delay_days=avg_delay,
        period_days=period_days,
    )


@router.get("/stats/chart", response_model=list[ChartDataPoint])
async def stats_chart(
    period_days: int = Query(30, ge=7, le=365),
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    """
    Séries temporelles jour par jour pour les graphiques du dashboard.
    Retourne une liste de points {date, declarations, matches, restitutions}.
    F-40 — Dashboard administrateur.
    """
    today = date.today()
    start = today - timedelta(days=period_days - 1)

    # Déclarations par jour
    decls_q = (
        select(
            func.date(Declaration.created_at).label("day"),
            func.count(Declaration.id).label("cnt"),
        )
        .where(func.date(Declaration.created_at) >= start)
        .group_by(func.date(Declaration.created_at))
    )
    decls_rows = {str(r.day): r.cnt for r in (await db.execute(decls_q)).all()}

    # Matchs par jour
    matches_q = (
        select(
            func.date(Match.created_at).label("day"),
            func.count(Match.id).label("cnt"),
        )
        .where(func.date(Match.created_at) >= start)
        .group_by(func.date(Match.created_at))
    )
    matches_rows = {str(r.day): r.cnt for r in (await db.execute(matches_q)).all()}

    # Restitutions complétées par jour
    restit_q = (
        select(
            func.date(Restitution.completed_at).label("day"),
            func.count(Restitution.id).label("cnt"),
        )
        .where(
            Restitution.status == "completed",
            Restitution.completed_at.isnot(None),
            func.date(Restitution.completed_at) >= start,
        )
        .group_by(func.date(Restitution.completed_at))
    )
    restit_rows = {str(r.day): r.cnt for r in (await db.execute(restit_q)).all()}

    points = []
    for i in range(period_days):
        day = str(start + timedelta(days=i))
        points.append(
            ChartDataPoint(
                date=day,
                declarations=decls_rows.get(day, 0),
                matches=matches_rows.get(day, 0),
                restitutions=restit_rows.get(day, 0),
            )
        )
    return points


# ─────────────────────────────────────────────────────────────────────────────
# Export CSV (F-41, F-42)
# ─────────────────────────────────────────────────────────────────────────────

@router.get("/export/declarations")
async def export_declarations_csv(
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    """
    Export CSV de toutes les déclarations. Utile pour les institutions.
    F-41 — Publication groupe / reporting.
    """
    declarations = (await db.execute(
        select(Declaration).order_by(Declaration.created_at.desc())
    )).scalars().all()

    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow([
        "id", "user_id", "document_type", "declaration_type",
        "status", "is_flagged", "created_at", "location_description",
    ])
    for d in declarations:
        writer.writerow([
            str(d.id), str(d.user_id), d.document_type,
            d.declaration_type, d.status,
            getattr(d, "is_flagged", False),
            d.created_at.isoformat(),
            getattr(d, "location_description", ""),
        ])
    output.seek(0)
    return StreamingResponse(
        iter([output.getvalue()]),
        media_type="text/csv",
        headers={"Content-Disposition": "attachment; filename=declarations_export.csv"},
    )


# ─────────────────────────────────────────────────────────────────────────────
# Gestion utilisateurs
# ─────────────────────────────────────────────────────────────────────────────

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
            User.phone_number.ilike(f"%{search}%")
            | User.full_name.ilike(f"%{search}%")
        )
    q = q.offset((page - 1) * per_page).limit(per_page)
    return (await db.execute(q)).scalars().all()


@router.patch("/users/{user_id}/ban", status_code=status.HTTP_200_OK)
async def ban_user(
    user_id: uuid.UUID,
    body: BanRequest,
    request: Request,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin),
):
    """Bannir un utilisateur (anti-fraude). Action auditée."""
    user = await db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="Utilisateur introuvable.")
    if user.id == admin.id:
        raise HTTPException(status_code=400, detail="Vous ne pouvez pas vous bannir vous-même.")
    user.is_banned = True  # type: ignore[assignment]
    await _audit(
        db, admin,
        action_type="user.ban",
        target_type="user",
        target_id=user_id,
        ip_address=_get_ip(request),
        extra={"reason": body.reason},
    )
    await db.commit()
    return {"detail": f"Utilisateur {user_id} banni. Raison : {body.reason}"}


@router.patch("/users/{user_id}/unban", status_code=status.HTTP_200_OK)
async def unban_user(
    user_id: uuid.UUID,
    request: Request,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin),
):
    """Rétablir un compte banni. Action auditée."""
    user = await db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="Utilisateur introuvable.")
    user.is_banned = False  # type: ignore[assignment]
    await _audit(
        db, admin,
        action_type="user.unban",
        target_type="user",
        target_id=user_id,
        ip_address=_get_ip(request),
    )
    await db.commit()
    return {"detail": f"Utilisateur {user_id} rétabli."}


@router.patch("/users/{user_id}/promote", status_code=status.HTTP_200_OK)
async def promote_to_admin(
    user_id: uuid.UUID,
    request: Request,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin),
):
    """Passer un utilisateur en mode admin. Action auditée."""
    user = await db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="Utilisateur introuvable.")
    user.is_admin = True  # type: ignore[assignment]
    await _audit(
        db, admin,
        action_type="user.promote",
        target_type="user",
        target_id=user_id,
        ip_address=_get_ip(request),
    )
    await db.commit()
    return {"detail": f"Utilisateur {user_id} promu administrateur."}


# ─────────────────────────────────────────────────────────────────────────────
# Modération déclarations
# ─────────────────────────────────────────────────────────────────────────────

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
    return (await db.execute(q)).scalars().all()


@router.delete("/declarations/{declaration_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_declaration(
    declaration_id: uuid.UUID,
    request: Request,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin),
):
    """Supprimer une déclaration frauduleuse. Action auditée."""
    decl = await db.get(Declaration, declaration_id)
    if not decl:
        raise HTTPException(status_code=404, detail="Déclaration introuvable.")
    await _audit(
        db, admin,
        action_type="declaration.delete",
        target_type="declaration",
        target_id=declaration_id,
        ip_address=_get_ip(request),
        extra={"document_type": decl.document_type, "user_id": str(decl.user_id)},
    )
    await db.delete(decl)
    await db.commit()


@router.patch("/declarations/{declaration_id}/flag")
async def flag_declaration(
    declaration_id: uuid.UUID,
    request: Request,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin),
):
    """Marquer une déclaration comme suspecte. Action auditée."""
    decl = await db.get(Declaration, declaration_id)
    if not decl:
        raise HTTPException(status_code=404, detail="Déclaration introuvable.")
    decl.is_flagged = True  # type: ignore[assignment]
    await _audit(
        db, admin,
        action_type="declaration.flag",
        target_type="declaration",
        target_id=declaration_id,
        ip_address=_get_ip(request),
    )
    await db.commit()
    return {"detail": "Déclaration marquée comme suspecte."}


@router.post("/declarations/bulk", status_code=status.HTTP_201_CREATED)
async def bulk_import_declarations(
    file: UploadFile = File(...),
    request: Request = None,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin),
):
    """
    Import en lot de déclarations depuis un fichier CSV.
    F-41 — Publication groupe de documents trouvés (institutions).

    Format CSV attendu (avec header) :
      document_type,owner_name,location_description,latitude,longitude,description

    Colonnes optionnelles : latitude, longitude, description.
    Toutes les déclarations importées ont declaration_type="found".
    """
    if file.content_type not in ("text/csv", "application/csv", "text/plain"):
        raise HTTPException(
            status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            detail="Seuls les fichiers CSV sont acceptés.",
        )

    content = (await file.read()).decode("utf-8", errors="replace")
    reader = csv.DictReader(io.StringIO(content))

    required_fields = {"document_type", "owner_name"}
    rows_created = 0
    errors = []

    for i, row in enumerate(reader, start=2):  # ligne 1 = header
        missing = required_fields - set(row.keys())
        if missing:
            errors.append({"row": i, "error": f"Colonnes manquantes : {missing}"})
            continue
        try:
            decl = Declaration(
                id=uuid.uuid4(),
                user_id=admin.id,         # rattachée au compte admin institutionnel
                declaration_type="found",
                document_type=row["document_type"].strip(),
                owner_name=row.get("owner_name", "").strip() or None,
                location_description=row.get("location_description", "").strip() or None,
                description=row.get("description", "").strip() or None,
                latitude=float(row["latitude"]) if row.get("latitude") else None,
                longitude=float(row["longitude"]) if row.get("longitude") else None,
                status="active",
            )
            db.add(decl)
            rows_created += 1
        except (ValueError, KeyError) as exc:
            errors.append({"row": i, "error": str(exc)})

    await _audit(
        db, admin,
        action_type="declaration.bulk_import",
        target_type="declaration",
        ip_address=_get_ip(request),
        extra={"rows_created": rows_created, "errors_count": len(errors)},
    )
    await db.commit()
    return {
        "rows_created": rows_created,
        "errors": errors,
    }


# ─────────────────────────────────────────────────────────────────────────────
# Matchs (F-40 dashboard)
# ─────────────────────────────────────────────────────────────────────────────

@router.get("/matches", response_model=list[MatchAdminRead])
async def list_all_matches(
    page: int = Query(1, ge=1),
    per_page: int = Query(50, ge=1, le=100),
    status_filter: Optional[str] = Query(None, alias="status"),
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    """
    Vue admin de tous les matchs (F-40 — dashboard institution).
    Filtre optionnel par statut : pending | confirmed | ignored | closed.
    """
    q = select(Match).order_by(Match.created_at.desc())
    if status_filter:
        q = q.where(Match.status == status_filter)
    q = q.offset((page - 1) * per_page).limit(per_page)
    return (await db.execute(q)).scalars().all()


# ─────────────────────────────────────────────────────────────────────────────
# Restitutions
# ─────────────────────────────────────────────────────────────────────────────

@router.get("/restitutions", response_model=list[RestitutionAdminRead])
async def list_all_restitutions(
    page: int = Query(1, ge=1),
    per_page: int = Query(50, ge=1, le=100),
    status_filter: Optional[str] = Query(None, alias="status"),
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    """
    Vue admin de toutes les restitutions.
    Filtre optionnel : pending | in_progress | completed | cancelled.
    """
    q = select(Restitution).order_by(Restitution.created_at.desc())
    if status_filter:
        q = q.where(Restitution.status == status_filter)
    q = q.offset((page - 1) * per_page).limit(per_page)
    return (await db.execute(q)).scalars().all()


# ─────────────────────────────────────────────────────────────────────────────
# Zones de récupération (F-32, F-43)
# ─────────────────────────────────────────────────────────────────────────────

@router.post("/zones", response_model=ZoneRead, status_code=status.HTTP_201_CREATED)
async def create_zone(
    body: ZoneCreate,
    request: Request,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin),
):
    """
    Ajouter un point de dépôt certifié (F-32 + F-43).
    Badge 'Point de dépôt certifié' sur la carte de l'app.
    """
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
    await _audit(
        db, admin,
        action_type="zone.create",
        target_type="zone",
        target_id=zone.id,
        ip_address=_get_ip(request),
        extra={"name": zone.name, "zone_type": zone.zone_type},
    )
    await db.commit()
    await db.refresh(zone)
    return zone


@router.get("/zones", response_model=list[ZoneRead])
async def list_zones(
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    """Lister tous les points de dépôt (vue admin complète)."""
    result = await db.execute(select(Zone).order_by(Zone.name))
    return result.scalars().all()


@router.patch("/zones/{zone_id}", response_model=ZoneRead)
async def update_zone(
    zone_id: uuid.UUID,
    body: ZoneUpdate,
    request: Request,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin),
):
    """Modifier un point de dépôt existant. Action auditée."""
    zone = await db.get(Zone, zone_id)
    if not zone:
        raise HTTPException(status_code=404, detail="Zone introuvable.")

    changes = body.model_dump(exclude_unset=True)
    for field, value in changes.items():
        setattr(zone, field, value)

    await _audit(
        db, admin,
        action_type="zone.update",
        target_type="zone",
        target_id=zone_id,
        ip_address=_get_ip(request),
        extra=changes,
    )
    await db.commit()
    await db.refresh(zone)
    return zone


@router.delete("/zones/{zone_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_zone(
    zone_id: uuid.UUID,
    request: Request,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin),
):
    """Supprimer un point de dépôt. Action auditée."""
    zone = await db.get(Zone, zone_id)
    if not zone:
        raise HTTPException(status_code=404, detail="Zone introuvable.")
    await _audit(
        db, admin,
        action_type="zone.delete",
        target_type="zone",
        target_id=zone_id,
        ip_address=_get_ip(request),
        extra={"name": zone.name},
    )
    await db.delete(zone)
    await db.commit()


# ─────────────────────────────────────────────────────────────────────────────
# Audit logs (CDC §11.1)
# ─────────────────────────────────────────────────────────────────────────────

@router.get("/audit-logs", response_model=list[AuditLogRead])
async def list_audit_logs(
    page: int = Query(1, ge=1),
    per_page: int = Query(50, ge=1, le=200),
    action_type: Optional[str] = None,
    admin_id: Optional[uuid.UUID] = None,
    since_days: int = Query(7, ge=1, le=365),
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    """
    Historique paginé des actions sensibles effectuées par les admins.
    CDC §11.1 — "Tous les accès aux données sensibles sont loggés."

    Filtres disponibles :
    - action_type : ex. "user.ban", "declaration.delete"
    - admin_id    : filtrer par admin
    - since_days  : fenêtre temporelle (défaut 7 jours)
    """
    since = datetime.now(timezone.utc) - timedelta(days=since_days)
    q = (
        select(AuditLog)
        .where(AuditLog.created_at >= since)
        .order_by(AuditLog.created_at.desc())
    )
    if action_type:
        q = q.where(AuditLog.action_type == action_type)
    if admin_id:
        q = q.where(AuditLog.admin_id == admin_id)
    q = q.offset((page - 1) * per_page).limit(per_page)
    return (await db.execute(q)).scalars().all()
