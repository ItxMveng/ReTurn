"""
Module Admin — Backoffice modération & analytics (F-40 à F-44)

Routes protégées par le rôle is_admin=True sur le modèle User.
Toutes les actions sensibles sont audit-loggées via _audit().

Routes disponibles :
  GET  /admin/stats                          — KPIs globaux (F-42)
  GET  /admin/stats/users                    — DAU, MAU, nouveaux, actifs
  GET  /admin/stats/reports                  — Stats signalements dashboard
  GET  /admin/stats/chart                    — Séries temporelles pour graphiques
  GET  /admin/export/declarations            — Export CSV (F-41)
  GET  /admin/users                          — Liste paginée + filtre
  GET  /admin/users/{id}                     — Profil complet d'un utilisateur
  PATCH /admin/users/{id}                    — Éditer nom/téléphone
  DELETE /admin/users/{id}                   — Suppression CPDP (soft delete)
  GET  /admin/users/{id}/sessions            — Historique connexions + IPs
  GET  /admin/users/{id}/export              — Export légal JSON complet
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
  GET  /admin/connection-logs                — Logs connexions globaux (traçabilité légale)
"""
import csv
import io
import json
import uuid
from datetime import datetime, date, timedelta, timezone
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, Request, UploadFile, File, status
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from sqlalchemy import func, select, or_
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.audit_log import AuditLog
from app.models.connection_log import ConnectionLog, ConnectionStatus
from app.models.declaration import Declaration
from app.models.match import Match
from app.models.report import Report, ReportReason, ReportStatus
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
    await db.flush()


def _get_ip(request: Optional[Request]) -> Optional[str]:
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


class UserStatsResponse(BaseModel):
    total_users: int
    active_last_7_days: int     # DAU hebdo
    active_last_30_days: int    # MAU
    new_last_7_days: int
    new_last_30_days: int
    banned_users: int
    admin_users: int


class ReportStatsResponse(BaseModel):
    total_reports: int
    pending: int
    reviewed: int
    resolved: int
    rejected: int
    by_reason: dict   # {reason: count}
    avg_resolution_days: Optional[float]


class ChartDataPoint(BaseModel):
    date: str
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


class UserAdminDetail(BaseModel):
    """Profil complet d'un utilisateur — vue admin."""
    id: uuid.UUID
    phone_number: str
    full_name: Optional[str]
    email: Optional[str]
    score_reputation: float
    is_admin: bool
    is_banned: bool
    is_active: bool
    created_at: datetime
    # Agrégats
    total_declarations: int
    total_matches: int
    total_reports_received: int   # signalements reçus
    total_reports_emitted: int    # signalements émis
    last_login_at: Optional[datetime]
    last_login_ip: Optional[str]

    class Config:
        from_attributes = True


class UserAdminUpdate(BaseModel):
    """Champs éditables par l'admin."""
    full_name: Optional[str] = None
    phone_number: Optional[str] = None
    is_active: Optional[bool] = None


class ConnectionLogRead(BaseModel):
    id: uuid.UUID
    user_id: Optional[uuid.UUID]
    phone_number: Optional[str]
    ip_address: Optional[str]
    user_agent: Optional[str]
    device_id: Optional[str]
    auth_method: str
    status: ConnectionStatus
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


@router.get("/stats/users", response_model=UserStatsResponse)
async def user_stats(
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    """
    Indicateurs d'activité utilisateurs : DAU, MAU, nouveaux inscrits, bannis.
    Un utilisateur "actif" = au moins une connexion réussie dans la période.
    """
    now = datetime.now(timezone.utc)
    since_7  = now - timedelta(days=7)
    since_30 = now - timedelta(days=30)

    total_users = (await db.execute(select(func.count(User.id)))).scalar_one()
    banned_users = (await db.execute(
        select(func.count(User.id)).where(User.is_banned == True)  # noqa: E712
    )).scalar_one()
    admin_users = (await db.execute(
        select(func.count(User.id)).where(User.is_admin == True)  # noqa: E712
    )).scalar_one()
    new_7 = (await db.execute(
        select(func.count(User.id)).where(User.created_at >= since_7)
    )).scalar_one()
    new_30 = (await db.execute(
        select(func.count(User.id)).where(User.created_at >= since_30)
    )).scalar_one()

    # Utilisateurs actifs = ayant eu une connexion SUCCESS dans la période
    active_7 = (await db.execute(
        select(func.count(func.distinct(ConnectionLog.user_id))).where(
            ConnectionLog.status == ConnectionStatus.SUCCESS,
            ConnectionLog.created_at >= since_7,
            ConnectionLog.user_id.isnot(None),
        )
    )).scalar_one()
    active_30 = (await db.execute(
        select(func.count(func.distinct(ConnectionLog.user_id))).where(
            ConnectionLog.status == ConnectionStatus.SUCCESS,
            ConnectionLog.created_at >= since_30,
            ConnectionLog.user_id.isnot(None),
        )
    )).scalar_one()

    return UserStatsResponse(
        total_users=total_users,
        active_last_7_days=active_7,
        active_last_30_days=active_30,
        new_last_7_days=new_7,
        new_last_30_days=new_30,
        banned_users=banned_users,
        admin_users=admin_users,
    )


@router.get("/stats/reports", response_model=ReportStatsResponse)
async def report_stats(
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    """Stats des signalements : total, par statut, par motif, délai moyen de résolution."""
    total = (await db.execute(select(func.count(Report.id)))).scalar_one()
    pending  = (await db.execute(select(func.count(Report.id)).where(Report.status == ReportStatus.PENDING))).scalar_one()
    reviewed = (await db.execute(select(func.count(Report.id)).where(Report.status == ReportStatus.REVIEWED))).scalar_one()
    resolved = (await db.execute(select(func.count(Report.id)).where(Report.status == ReportStatus.RESOLVED))).scalar_one()
    rejected = (await db.execute(select(func.count(Report.id)).where(Report.status == ReportStatus.REJECTED))).scalar_one()

    # Répartition par motif
    by_reason: dict = {}
    for reason in ReportReason:
        cnt = (await db.execute(
            select(func.count(Report.id)).where(Report.reason == reason)
        )).scalar_one()
        by_reason[reason.value] = cnt

    # Délai moyen de résolution (en jours)
    avg_delay = None
    raw = (await db.execute(
        select(func.avg(
            func.extract("epoch", Report.resolved_at - Report.created_at)
        )).where(
            Report.resolved_at.isnot(None),
            Report.status.in_([ReportStatus.RESOLVED, ReportStatus.REJECTED]),
        )
    )).scalar_one()
    if raw is not None:
        avg_delay = round(raw / 86400, 1)

    return ReportStatsResponse(
        total_reports=total,
        pending=pending,
        reviewed=reviewed,
        resolved=resolved,
        rejected=rejected,
        by_reason=by_reason,
        avg_resolution_days=avg_delay,
    )


@router.get("/stats/chart", response_model=list[ChartDataPoint])
async def stats_chart(
    period_days: int = Query(30, ge=7, le=365),
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    today = date.today()
    start = today - timedelta(days=period_days - 1)

    decls_q = (
        select(func.date(Declaration.created_at).label("day"), func.count(Declaration.id).label("cnt"))
        .where(func.date(Declaration.created_at) >= start)
        .group_by(func.date(Declaration.created_at))
    )
    decls_rows = {str(r.day): r.cnt for r in (await db.execute(decls_q)).all()}

    matches_q = (
        select(func.date(Match.created_at).label("day"), func.count(Match.id).label("cnt"))
        .where(func.date(Match.created_at) >= start)
        .group_by(func.date(Match.created_at))
    )
    matches_rows = {str(r.day): r.cnt for r in (await db.execute(matches_q)).all()}

    restit_q = (
        select(func.date(Restitution.completed_at).label("day"), func.count(Restitution.id).label("cnt"))
        .where(Restitution.status == "completed", Restitution.completed_at.isnot(None), func.date(Restitution.completed_at) >= start)
        .group_by(func.date(Restitution.completed_at))
    )
    restit_rows = {str(r.day): r.cnt for r in (await db.execute(restit_q)).all()}

    return [
        ChartDataPoint(
            date=str(start + timedelta(days=i)),
            declarations=decls_rows.get(str(start + timedelta(days=i)), 0),
            matches=matches_rows.get(str(start + timedelta(days=i)), 0),
            restitutions=restit_rows.get(str(start + timedelta(days=i)), 0),
        )
        for i in range(period_days)
    ]


# ─────────────────────────────────────────────────────────────────────────────
# Export CSV (F-41, F-42)
# ─────────────────────────────────────────────────────────────────────────────

@router.get("/export/declarations")
async def export_declarations_csv(
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    declarations = (await db.execute(
        select(Declaration).order_by(Declaration.created_at.desc())
    )).scalars().all()

    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow(["id", "user_id", "document_type", "declaration_type", "status", "is_flagged", "created_at", "location_description"])
    for d in declarations:
        writer.writerow([
            str(d.id), str(d.user_id), d.document_type, d.declaration_type,
            d.status, getattr(d, "is_flagged", False), d.created_at.isoformat(),
            getattr(d, "location_description", ""),
        ])
    output.seek(0)
    return StreamingResponse(
        iter([output.getvalue()]),
        media_type="text/csv",
        headers={"Content-Disposition": "attachment; filename=declarations_export.csv"},
    )


# ─────────────────────────────────────────────────────────────────────────────
# Gestion utilisateurs — CRUD complet
# ─────────────────────────────────────────────────────────────────────────────

@router.get("/users", response_model=list[UserAdminRead])
async def list_users(
    page: int = Query(1, ge=1),
    per_page: int = Query(50, ge=1, le=100),
    search: Optional[str] = None,
    is_banned: Optional[bool] = None,
    is_admin: Optional[bool] = None,
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    """Liste paginée des utilisateurs avec filtres : recherche, banni, admin."""
    q = select(User).order_by(User.created_at.desc())
    if search:
        q = q.where(or_(User.phone_number.ilike(f"%{search}%"), User.full_name.ilike(f"%{search}%")))
    if is_banned is not None:
        q = q.where(User.is_banned == is_banned)
    if is_admin is not None:
        q = q.where(User.is_admin == is_admin)
    q = q.offset((page - 1) * per_page).limit(per_page)
    return (await db.execute(q)).scalars().all()


@router.get("/users/{user_id}", response_model=UserAdminDetail)
async def get_user_detail(
    user_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    """Profil complet d'un utilisateur : déclarations, matchs, signalements, dernière connexion."""
    user = await db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="Utilisateur introuvable.")

    total_decls = (await db.execute(
        select(func.count(Declaration.id)).where(Declaration.user_id == user_id)
    )).scalar_one()
    total_matches = (await db.execute(
        select(func.count(Match.id)).where(
            or_(Match.user_found_id == user_id, Match.user_lost_id == user_id)
        )
    )).scalar_one()
    total_reports_received = (await db.execute(
        select(func.count(Report.id)).where(Report.reported_id == user_id)
    )).scalar_one()
    total_reports_emitted = (await db.execute(
        select(func.count(Report.id)).where(Report.reporter_id == user_id)
    )).scalar_one()

    # Dernière connexion réussie
    last_log = (await db.execute(
        select(ConnectionLog)
        .where(ConnectionLog.user_id == user_id, ConnectionLog.status == ConnectionStatus.SUCCESS)
        .order_by(ConnectionLog.created_at.desc())
        .limit(1)
    )).scalar_one_or_none()

    return UserAdminDetail(
        id=user.id,
        phone_number=user.phone_number,
        full_name=getattr(user, "full_name", None),
        email=getattr(user, "email", None),
        score_reputation=getattr(user, "score_reputation", 0.0),
        is_admin=getattr(user, "is_admin", False),
        is_banned=getattr(user, "is_banned", False),
        is_active=getattr(user, "is_active", True),
        created_at=user.created_at,
        total_declarations=total_decls,
        total_matches=total_matches,
        total_reports_received=total_reports_received,
        total_reports_emitted=total_reports_emitted,
        last_login_at=last_log.created_at if last_log else None,
        last_login_ip=last_log.ip_address if last_log else None,
    )


@router.patch("/users/{user_id}", response_model=UserAdminRead)
async def update_user(
    user_id: uuid.UUID,
    body: UserAdminUpdate,
    request: Request,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin),
):
    """Modifier les données d'un utilisateur (nom, téléphone, actif/inactif). Action auditée."""
    user = await db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="Utilisateur introuvable.")

    changes = body.model_dump(exclude_unset=True)
    for field, value in changes.items():
        setattr(user, field, value)

    await _audit(
        db, admin,
        action_type="user.update",
        target_type="user",
        target_id=user_id,
        ip_address=_get_ip(request),
        extra=changes,
    )
    await db.commit()
    await db.refresh(user)
    return user


@router.delete("/users/{user_id}", status_code=status.HTTP_200_OK)
async def delete_user(
    user_id: uuid.UUID,
    request: Request,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin),
):
    """
    Suppression CPDP (droit à l'effacement) — soft delete.
    Le compte est désactivé et anonymisé : nom → 'Utilisateur supprimé',
    téléphone → UUID hash, is_active → False.
    Les données sont conservées 5 ans pour obligations légales.
    """
    user = await db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="Utilisateur introuvable.")
    if user.id == admin.id:
        raise HTTPException(status_code=400, detail="Impossible de supprimer votre propre compte.")

    # Anonymisation CPDP
    anon_id = str(uuid.uuid4())[:8]
    user.full_name = "Utilisateur supprimé"  # type: ignore[assignment]
    user.phone_number = f"deleted_{anon_id}"  # type: ignore[assignment]
    user.is_active = False  # type: ignore[assignment]
    if hasattr(user, "fcm_token"):
        user.fcm_token = None  # type: ignore[assignment]

    await _audit(
        db, admin,
        action_type="user.delete_gdpr",
        target_type="user",
        target_id=user_id,
        ip_address=_get_ip(request),
        extra={"anon_id": anon_id},
    )
    await db.commit()
    return {"detail": f"Compte {user_id} anonymisé et désactivé (CPDP). Données conservées 5 ans."}


@router.get("/users/{user_id}/sessions", response_model=list[ConnectionLogRead])
async def get_user_sessions(
    user_id: uuid.UUID,
    limit: int = Query(100, le=500),
    since_days: int = Query(30, ge=1, le=365),
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    """
    Historique complet des connexions d'un utilisateur :
    dates, IPs, devices, statuts (success/failed/banned).
    Utilisable pour répondre à une réquisition judiciaire.
    """
    since = datetime.now(timezone.utc) - timedelta(days=since_days)
    result = await db.execute(
        select(ConnectionLog)
        .where(
            ConnectionLog.user_id == user_id,
            ConnectionLog.created_at >= since,
        )
        .order_by(ConnectionLog.created_at.desc())
        .limit(limit)
    )
    return result.scalars().all()


@router.get("/users/{user_id}/export")
async def export_user_legal(
    user_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin),
    request: Request = None,
):
    """
    Export légal complet d'un utilisateur au format JSON.
    Contient : profil, déclarations, matchs, sessions de connexion, signalements.
    Utilisable pour :
    - Réquisitions judiciaires (ANSSI, parquet)
    - Demandes CPDP (droit d'accès)
    - Audits internes
    """
    user = await db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="Utilisateur introuvable.")

    # Déclarations
    decls = (await db.execute(
        select(Declaration).where(Declaration.user_id == user_id).order_by(Declaration.created_at)
    )).scalars().all()

    # Matchs
    matches = (await db.execute(
        select(Match).where(
            or_(Match.user_found_id == user_id, Match.user_lost_id == user_id)
        ).order_by(Match.created_at)
    )).scalars().all()

    # Sessions de connexion (12 derniers mois)
    since_1y = datetime.now(timezone.utc) - timedelta(days=365)
    sessions = (await db.execute(
        select(ConnectionLog)
        .where(ConnectionLog.user_id == user_id, ConnectionLog.created_at >= since_1y)
        .order_by(ConnectionLog.created_at)
    )).scalars().all()

    # Signalements reçus
    reports_received = (await db.execute(
        select(Report).where(Report.reported_id == user_id)
    )).scalars().all()

    # Signalements émis
    reports_emitted = (await db.execute(
        select(Report).where(Report.reporter_id == user_id)
    )).scalars().all()

    await _audit(
        db, admin,
        action_type="user.legal_export",
        target_type="user",
        target_id=user_id,
        ip_address=_get_ip(request),
        extra={"exported_at": datetime.now(timezone.utc).isoformat()},
    )
    await db.commit()

    export_data = {
        "exported_at": datetime.now(timezone.utc).isoformat(),
        "exported_by_admin": str(admin.id),
        "user": {
            "id": str(user.id),
            "phone_number": user.phone_number,
            "full_name": getattr(user, "full_name", None),
            "email": getattr(user, "email", None),
            "score_reputation": getattr(user, "score_reputation", 0.0),
            "is_banned": getattr(user, "is_banned", False),
            "is_active": getattr(user, "is_active", True),
            "created_at": user.created_at.isoformat(),
        },
        "declarations": [
            {
                "id": str(d.id),
                "document_type": d.document_type,
                "declaration_type": d.declaration_type,
                "status": d.status,
                "created_at": d.created_at.isoformat(),
            }
            for d in decls
        ],
        "matches": [
            {
                "id": str(m.id),
                "score": m.score,
                "status": m.status,
                "created_at": m.created_at.isoformat(),
            }
            for m in matches
        ],
        "connection_logs": [
            {
                "id": str(s.id),
                "ip_address": s.ip_address,
                "user_agent": s.user_agent,
                "device_id": s.device_id,
                "auth_method": s.auth_method,
                "status": s.status.value,
                "created_at": s.created_at.isoformat(),
            }
            for s in sessions
        ],
        "reports_received": [
            {
                "id": str(r.id),
                "reason": r.reason.value,
                "status": r.status.value,
                "created_at": r.created_at.isoformat(),
            }
            for r in reports_received
        ],
        "reports_emitted": [
            {
                "id": str(r.id),
                "reason": r.reason.value,
                "status": r.status.value,
                "created_at": r.created_at.isoformat(),
            }
            for r in reports_emitted
        ],
    }

    json_bytes = json.dumps(export_data, ensure_ascii=False, indent=2).encode("utf-8")
    filename = f"user_{user_id}_legal_export_{date.today().isoformat()}.json"
    return StreamingResponse(
        iter([json_bytes]),
        media_type="application/json",
        headers={"Content-Disposition": f"attachment; filename={filename}"},
    )


@router.patch("/users/{user_id}/ban", status_code=status.HTTP_200_OK)
async def ban_user(
    user_id: uuid.UUID,
    body: BanRequest,
    request: Request,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin),
):
    user = await db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="Utilisateur introuvable.")
    if user.id == admin.id:
        raise HTTPException(status_code=400, detail="Vous ne pouvez pas vous bannir vous-même.")
    user.is_banned = True  # type: ignore[assignment]
    await _audit(db, admin, "user.ban", "user", user_id, _get_ip(request), {"reason": body.reason})
    await db.commit()
    return {"detail": f"Utilisateur {user_id} banni. Raison : {body.reason}"}


@router.patch("/users/{user_id}/unban", status_code=status.HTTP_200_OK)
async def unban_user(
    user_id: uuid.UUID,
    request: Request,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin),
):
    user = await db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="Utilisateur introuvable.")
    user.is_banned = False  # type: ignore[assignment]
    await _audit(db, admin, "user.unban", "user", user_id, _get_ip(request))
    await db.commit()
    return {"detail": f"Utilisateur {user_id} rétabli."}


@router.patch("/users/{user_id}/promote", status_code=status.HTTP_200_OK)
async def promote_to_admin(
    user_id: uuid.UUID,
    request: Request,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin),
):
    user = await db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="Utilisateur introuvable.")
    user.is_admin = True  # type: ignore[assignment]
    await _audit(db, admin, "user.promote", "user", user_id, _get_ip(request))
    await db.commit()
    return {"detail": f"Utilisateur {user_id} promu administrateur."}


# ─────────────────────────────────────────────────────────────────────────────
# Logs de connexion globaux (traçabilité légale)
# ─────────────────────────────────────────────────────────────────────────────

@router.get("/connection-logs", response_model=list[ConnectionLogRead])
async def list_connection_logs(
    page: int = Query(1, ge=1),
    per_page: int = Query(50, ge=1, le=200),
    status_filter: Optional[ConnectionStatus] = Query(None, alias="status"),
    user_id: Optional[uuid.UUID] = None,
    ip_address: Optional[str] = None,
    since_days: int = Query(7, ge=1, le=365),
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    """
    Logs de connexion globaux avec filtres :
    - par statut (success/failed/banned/suspicious)
    - par utilisateur
    - par adresse IP (pour identifier des accès frauduleux)
    - par période
    Indispensable pour répondre aux réquisitions judiciaires.
    """
    since = datetime.now(timezone.utc) - timedelta(days=since_days)
    q = select(ConnectionLog).where(ConnectionLog.created_at >= since).order_by(ConnectionLog.created_at.desc())
    if status_filter:
        q = q.where(ConnectionLog.status == status_filter)
    if user_id:
        q = q.where(ConnectionLog.user_id == user_id)
    if ip_address:
        q = q.where(ConnectionLog.ip_address == ip_address)
    q = q.offset((page - 1) * per_page).limit(per_page)
    return (await db.execute(q)).scalars().all()


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
    decl = await db.get(Declaration, declaration_id)
    if not decl:
        raise HTTPException(status_code=404, detail="Déclaration introuvable.")
    await _audit(db, admin, "declaration.delete", "declaration", declaration_id, _get_ip(request),
                 {"document_type": decl.document_type, "user_id": str(decl.user_id)})
    await db.delete(decl)
    await db.commit()


@router.patch("/declarations/{declaration_id}/flag")
async def flag_declaration(
    declaration_id: uuid.UUID,
    request: Request,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin),
):
    decl = await db.get(Declaration, declaration_id)
    if not decl:
        raise HTTPException(status_code=404, detail="Déclaration introuvable.")
    decl.is_flagged = True  # type: ignore[assignment]
    await _audit(db, admin, "declaration.flag", "declaration", declaration_id, _get_ip(request))
    await db.commit()
    return {"detail": "Déclaration marquée comme suspecte."}


@router.post("/declarations/bulk", status_code=status.HTTP_201_CREATED)
async def bulk_import_declarations(
    file: UploadFile = File(...),
    request: Request = None,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin),
):
    if file.content_type not in ("text/csv", "application/csv", "text/plain"):
        raise HTTPException(status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE, detail="Seuls les fichiers CSV sont acceptés.")

    content = (await file.read()).decode("utf-8", errors="replace")
    reader = csv.DictReader(io.StringIO(content))
    required_fields = {"document_type", "owner_name"}
    rows_created, errors = 0, []

    for i, row in enumerate(reader, start=2):
        missing = required_fields - set(row.keys())
        if missing:
            errors.append({"row": i, "error": f"Colonnes manquantes : {missing}"})
            continue
        try:
            decl = Declaration(
                id=uuid.uuid4(), user_id=admin.id, declaration_type="found",
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

    await _audit(db, admin, "declaration.bulk_import", "declaration", None, _get_ip(request),
                 {"rows_created": rows_created, "errors_count": len(errors)})
    await db.commit()
    return {"rows_created": rows_created, "errors": errors}


# ─────────────────────────────────────────────────────────────────────────────
# Matchs & Restitutions
# ─────────────────────────────────────────────────────────────────────────────

@router.get("/matches", response_model=list[MatchAdminRead])
async def list_all_matches(
    page: int = Query(1, ge=1),
    per_page: int = Query(50, ge=1, le=100),
    status_filter: Optional[str] = Query(None, alias="status"),
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    q = select(Match).order_by(Match.created_at.desc())
    if status_filter:
        q = q.where(Match.status == status_filter)
    q = q.offset((page - 1) * per_page).limit(per_page)
    return (await db.execute(q)).scalars().all()


@router.get("/restitutions", response_model=list[RestitutionAdminRead])
async def list_all_restitutions(
    page: int = Query(1, ge=1),
    per_page: int = Query(50, ge=1, le=100),
    status_filter: Optional[str] = Query(None, alias="status"),
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
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
    body: ZoneCreate, request: Request,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin),
):
    zone = Zone(id=uuid.uuid4(), name=body.name, zone_type=body.zone_type,
                latitude=body.latitude, longitude=body.longitude, address=body.address,
                institution_id=body.institution_id, is_certified=body.is_certified)
    db.add(zone)
    await _audit(db, admin, "zone.create", "zone", zone.id, _get_ip(request),
                 {"name": zone.name, "zone_type": zone.zone_type})
    await db.commit()
    await db.refresh(zone)
    return zone


@router.get("/zones", response_model=list[ZoneRead])
async def list_zones(db: AsyncSession = Depends(get_db), _admin: User = Depends(require_admin)):
    return (await db.execute(select(Zone).order_by(Zone.name))).scalars().all()


@router.patch("/zones/{zone_id}", response_model=ZoneRead)
async def update_zone(
    zone_id: uuid.UUID, body: ZoneUpdate, request: Request,
    db: AsyncSession = Depends(get_db), admin: User = Depends(require_admin),
):
    zone = await db.get(Zone, zone_id)
    if not zone:
        raise HTTPException(status_code=404, detail="Zone introuvable.")
    changes = body.model_dump(exclude_unset=True)
    for field, value in changes.items():
        setattr(zone, field, value)
    await _audit(db, admin, "zone.update", "zone", zone_id, _get_ip(request), changes)
    await db.commit()
    await db.refresh(zone)
    return zone


@router.delete("/zones/{zone_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_zone(
    zone_id: uuid.UUID, request: Request,
    db: AsyncSession = Depends(get_db), admin: User = Depends(require_admin),
):
    zone = await db.get(Zone, zone_id)
    if not zone:
        raise HTTPException(status_code=404, detail="Zone introuvable.")
    await _audit(db, admin, "zone.delete", "zone", zone_id, _get_ip(request), {"name": zone.name})
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
    since = datetime.now(timezone.utc) - timedelta(days=since_days)
    q = select(AuditLog).where(AuditLog.created_at >= since).order_by(AuditLog.created_at.desc())
    if action_type:
        q = q.where(AuditLog.action_type == action_type)
    if admin_id:
        q = q.where(AuditLog.admin_id == admin_id)
    q = q.offset((page - 1) * per_page).limit(per_page)
    return (await db.execute(q)).scalars().all()
