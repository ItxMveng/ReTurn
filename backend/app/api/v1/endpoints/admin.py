"""
Module Admin — Backoffice modération & analytics

Routes protégées par le rôle is_admin=True sur le modèle User.
Toutes les actions sensibles sont audit-loggées via _audit().

Routes disponibles :
  ── Analytics ──
  GET  /admin/stats                          — KPIs globaux
  GET  /admin/stats/users                    — DAU, MAU, nouveaux, actifs (NOUVEAU)
  GET  /admin/stats/reports                  — Stats signalements (NOUVEAU)
  GET  /admin/stats/chart                    — Séries temporelles graphiques
  ── Utilisateurs ──
  GET  /admin/users                          — Liste paginée + filtre
  GET  /admin/users/{id}                     — Profil complet (NOUVEAU)
  PATCH /admin/users/{id}                    — Éditer nom/téléphone (NOUVEAU)
  DELETE /admin/users/{id}                   — Soft-delete CPDP (NOUVEAU)
  PATCH /admin/users/{id}/ban                — Bannir
  PATCH /admin/users/{id}/unban              — Rétablir
  PATCH /admin/users/{id}/promote            — Promouvoir admin
  GET  /admin/users/{id}/sessions            — Historique connexions + IPs (NOUVEAU)
  GET  /admin/users/{id}/export              — Export légal JSON CPDP (NOUVEAU)
  ── Déclarations ──
  GET  /admin/declarations                   — Toutes déclarations (filtre flagged)
  DELETE /admin/declarations/{id}            — Supprimer (modération)
  PATCH /admin/declarations/{id}/flag        — Marquer suspect
  POST /admin/declarations/bulk              — Import lot CSV
  GET  /admin/export/declarations            — Export CSV
  ── Matchs & Restitutions ──
  GET  /admin/matches                        — Tous les matchs
  GET  /admin/restitutions                   — Toutes les restitutions
  ── Zones ──
  GET/POST/PATCH/DELETE /admin/zones         — CRUD zones certifiées
  ── Audit & Sécurité ──
  GET  /admin/audit-logs                     — Historique actions admin
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
from app.models.report import Report, ReportStatus
from app.models.restitution import Restitution
from app.models.user import User
from app.models.zone import Zone

router = APIRouter(prefix="/admin", tags=["admin"])


# ─────────────────────────────────────────────────────────────────────────────
# Guard
# ─────────────────────────────────────────────────────────────────────────────

async def require_admin(current_user: User = Depends(get_current_user)) -> User:
    if not getattr(current_user, "is_admin", False):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Accès réservé aux administrateurs.")
    return current_user


# ─────────────────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────────────────

async def _audit(
    db: AsyncSession, admin: User, action_type: str,
    target_type: Optional[str] = None, target_id: Optional[str] = None,
    ip_address: Optional[str] = None, extra: Optional[dict] = None,
) -> None:
    log = AuditLog(
        id=uuid.uuid4(), admin_id=admin.id, action_type=action_type,
        target_type=target_type, target_id=str(target_id) if target_id else None,
        ip_address=ip_address, extra=extra or {},
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
    active_last_7d: int
    active_last_30d: int
    new_last_7d: int
    new_last_30d: int
    banned_users: int
    admin_users: int
    connections_last_24h: int
    failed_logins_last_24h: int

class ReportStatsResponse(BaseModel):
    total_reports: int
    pending: int
    reviewed: int
    resolved: int
    rejected: int
    by_reason: dict
    avg_resolution_hours: Optional[float]

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
    is_active: bool
    created_at: datetime
    class Config:
        from_attributes = True

class UserAdminDetail(BaseModel):
    id: uuid.UUID
    phone_number: str
    full_name: Optional[str]
    email: Optional[str]
    score_reputation: float
    is_admin: bool
    is_banned: bool
    is_active: bool
    created_at: datetime
    total_declarations: int
    total_matches: int
    total_reports_emitted: int
    total_reports_received: int
    last_seen: Optional[datetime]
    class Config:
        from_attributes = True

class UserAdminUpdate(BaseModel):
    full_name: Optional[str] = None
    phone_number: Optional[str] = None

class ConnectionLogRead(BaseModel):
    id: uuid.UUID
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
# ANALYTICS
# ─────────────────────────────────────────────────────────────────────────────

@router.get("/stats", response_model=GlobalStatsResponse)
async def global_stats(
    period_days: int = Query(30, ge=1, le=365),
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    since = datetime.now(timezone.utc) - timedelta(days=period_days)
    total_users   = (await db.execute(select(func.count(User.id)))).scalar_one()
    total_decls   = (await db.execute(select(func.count(Declaration.id)).where(Declaration.created_at >= since))).scalar_one()
    total_matches = (await db.execute(select(func.count(Match.id)).where(Match.created_at >= since))).scalar_one()
    total_completed = (await db.execute(
        select(func.count(Restitution.id)).where(Restitution.status == "completed", Restitution.created_at >= since)
    )).scalar_one()
    success_rate = (total_completed / total_matches * 100) if total_matches > 0 else 0.0
    avg_delay = None
    raw_avg = (await db.execute(
        select(func.avg(func.extract("epoch", Restitution.completed_at - Restitution.created_at)))
        .where(Restitution.status == "completed", Restitution.completed_at.isnot(None))
    )).scalar_one()
    if raw_avg is not None:
        avg_delay = round(raw_avg / 86400, 1)
    return GlobalStatsResponse(
        total_users=total_users, total_declarations=total_decls,
        total_matches=total_matches, total_restitutions_completed=total_completed,
        restitution_success_rate=round(success_rate, 1),
        avg_restitution_delay_days=avg_delay, period_days=period_days,
    )


@router.get("/stats/users", response_model=UserStatsResponse)
async def user_stats(
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    """
    Indicateurs utilisateurs avancés :
    - DAU (actifs 7j) et MAU (actifs 30j) basés sur les connexions réussies
    - Nouveaux inscrits sur 7j et 30j
    - Comptes bannis et admins
    - Connexions et échecs des dernières 24h
    """
    now = datetime.now(timezone.utc)
    d7  = now - timedelta(days=7)
    d30 = now - timedelta(days=30)
    d1  = now - timedelta(hours=24)

    total_users = (await db.execute(select(func.count(User.id)))).scalar_one()
    banned      = (await db.execute(select(func.count(User.id)).where(User.is_banned == True))).scalar_one()  # noqa
    admins      = (await db.execute(select(func.count(User.id)).where(User.is_admin == True))).scalar_one()   # noqa
    new_7d      = (await db.execute(select(func.count(User.id)).where(User.created_at >= d7))).scalar_one()
    new_30d     = (await db.execute(select(func.count(User.id)).where(User.created_at >= d30))).scalar_one()

    # Utilisateurs actifs = ceux qui ont eu une connexion SUCCESS dans la fenêtre
    active_7d = (await db.execute(
        select(func.count(func.distinct(ConnectionLog.user_id)))
        .where(ConnectionLog.status == ConnectionStatus.SUCCESS, ConnectionLog.created_at >= d7)
    )).scalar_one()
    active_30d = (await db.execute(
        select(func.count(func.distinct(ConnectionLog.user_id)))
        .where(ConnectionLog.status == ConnectionStatus.SUCCESS, ConnectionLog.created_at >= d30)
    )).scalar_one()

    # Connexions 24h
    conn_24h = (await db.execute(
        select(func.count(ConnectionLog.id)).where(ConnectionLog.created_at >= d1)
    )).scalar_one()
    failed_24h = (await db.execute(
        select(func.count(ConnectionLog.id))
        .where(ConnectionLog.status == ConnectionStatus.FAILED, ConnectionLog.created_at >= d1)
    )).scalar_one()

    return UserStatsResponse(
        total_users=total_users, active_last_7d=active_7d, active_last_30d=active_30d,
        new_last_7d=new_7d, new_last_30d=new_30d, banned_users=banned, admin_users=admins,
        connections_last_24h=conn_24h, failed_logins_last_24h=failed_24h,
    )


@router.get("/stats/reports", response_model=ReportStatsResponse)
async def report_stats(
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    """Stats des signalements pour le dashboard admin."""
    total = (await db.execute(select(func.count(Report.id)))).scalar_one()
    pending  = (await db.execute(select(func.count(Report.id)).where(Report.status == ReportStatus.PENDING))).scalar_one()
    reviewed = (await db.execute(select(func.count(Report.id)).where(Report.status == ReportStatus.REVIEWED))).scalar_one()
    resolved = (await db.execute(select(func.count(Report.id)).where(Report.status == ReportStatus.RESOLVED))).scalar_one()
    rejected = (await db.execute(select(func.count(Report.id)).where(Report.status == ReportStatus.REJECTED))).scalar_one()

    # Répartition par motif
    from app.models.report import ReportReason
    by_reason = {}
    for reason in ReportReason:
        cnt = (await db.execute(
            select(func.count(Report.id)).where(Report.reason == reason)
        )).scalar_one()
        by_reason[reason.value] = cnt

    # Délai moyen de résolution (heures)
    avg_hours = None
    raw = (await db.execute(
        select(func.avg(func.extract("epoch", Report.resolved_at - Report.created_at)))
        .where(Report.resolved_at.isnot(None))
    )).scalar_one()
    if raw is not None:
        avg_hours = round(raw / 3600, 1)

    return ReportStatsResponse(
        total_reports=total, pending=pending, reviewed=reviewed,
        resolved=resolved, rejected=rejected, by_reason=by_reason,
        avg_resolution_hours=avg_hours,
    )


@router.get("/stats/chart", response_model=list[ChartDataPoint])
async def stats_chart(
    period_days: int = Query(30, ge=7, le=365),
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    today = date.today()
    start = today - timedelta(days=period_days - 1)
    decls_q = (select(func.date(Declaration.created_at).label("day"), func.count(Declaration.id).label("cnt"))
               .where(func.date(Declaration.created_at) >= start).group_by(func.date(Declaration.created_at)))
    decls_rows = {str(r.day): r.cnt for r in (await db.execute(decls_q)).all()}
    matches_q = (select(func.date(Match.created_at).label("day"), func.count(Match.id).label("cnt"))
                 .where(func.date(Match.created_at) >= start).group_by(func.date(Match.created_at)))
    matches_rows = {str(r.day): r.cnt for r in (await db.execute(matches_q)).all()}
    restit_q = (select(func.date(Restitution.completed_at).label("day"), func.count(Restitution.id).label("cnt"))
                .where(Restitution.status == "completed", Restitution.completed_at.isnot(None),
                       func.date(Restitution.completed_at) >= start).group_by(func.date(Restitution.completed_at)))
    restit_rows = {str(r.day): r.cnt for r in (await db.execute(restit_q)).all()}
    points = []
    for i in range(period_days):
        day = str(start + timedelta(days=i))
        points.append(ChartDataPoint(date=day, declarations=decls_rows.get(day, 0),
                                     matches=matches_rows.get(day, 0), restitutions=restit_rows.get(day, 0)))
    return points


# ─────────────────────────────────────────────────────────────────────────────
# GESTION UTILISATEURS
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
    """Liste paginée des utilisateurs. Filtres : search, is_banned, is_admin."""
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
    """Profil complet d'un utilisateur : données + compteurs d'activité."""
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
    reports_emitted = (await db.execute(
        select(func.count(Report.id)).where(Report.reporter_id == user_id)
    )).scalar_one()
    reports_received = (await db.execute(
        select(func.count(Report.id)).where(Report.reported_id == user_id)
    )).scalar_one()

    # Dernière connexion réussie
    last_conn = (await db.execute(
        select(ConnectionLog.created_at)
        .where(ConnectionLog.user_id == user_id, ConnectionLog.status == ConnectionStatus.SUCCESS)
        .order_by(ConnectionLog.created_at.desc()).limit(1)
    )).scalar_one_or_none()

    return {
        "id": user.id, "phone_number": user.phone_number,
        "full_name": getattr(user, "full_name", None),
        "email": getattr(user, "email", None),
        "score_reputation": getattr(user, "score_reputation", 0.0),
        "is_admin": getattr(user, "is_admin", False),
        "is_banned": getattr(user, "is_banned", False),
        "is_active": getattr(user, "is_active", True),
        "created_at": user.created_at,
        "total_declarations": total_decls,
        "total_matches": total_matches,
        "total_reports_emitted": reports_emitted,
        "total_reports_received": reports_received,
        "last_seen": last_conn,
    }


@router.patch("/users/{user_id}", response_model=UserAdminRead)
async def update_user(
    user_id: uuid.UUID,
    body: UserAdminUpdate,
    request: Request,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin),
):
    """[Admin] Modifier le nom ou le numéro de téléphone d'un utilisateur. Action auditée."""
    user = await db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="Utilisateur introuvable.")
    changes = body.model_dump(exclude_unset=True)
    for field, value in changes.items():
        setattr(user, field, value)
    await _audit(db, admin, "user.update", "user", user_id, _get_ip(request), extra=changes)
    await db.commit()
    await db.refresh(user)
    return user


@router.delete("/users/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_user(
    user_id: uuid.UUID,
    request: Request,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin),
):
    """
    [Admin] Soft-delete CPDP : anonymise le compte (droit à l'effacement).
    Les données sont anonymisées, pas supprimées, pour préserver l'intégrité
    référentielle et les obligations légales de conservation.
    """
    user = await db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="Utilisateur introuvable.")
    if user.id == admin.id:
        raise HTTPException(status_code=400, detail="Vous ne pouvez pas supprimer votre propre compte.")

    # Anonymisation (soft delete CPDP)
    anon_id = str(uuid.uuid4())[:8]
    user.phone_number = f"deleted_{anon_id}"
    if hasattr(user, "full_name"):
        user.full_name = None
    if hasattr(user, "email"):
        user.email = None
    if hasattr(user, "fcm_token"):
        user.fcm_token = None
    user.is_active = False  # type: ignore[assignment]

    await _audit(db, admin, "user.delete", "user", user_id, _get_ip(request),
                 extra={"anonymized": True, "anon_suffix": anon_id})
    await db.commit()


@router.patch("/users/{user_id}/ban", status_code=status.HTTP_200_OK)
async def ban_user(
    user_id: uuid.UUID, body: BanRequest, request: Request,
    db: AsyncSession = Depends(get_db), admin: User = Depends(require_admin),
):
    user = await db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="Utilisateur introuvable.")
    if user.id == admin.id:
        raise HTTPException(status_code=400, detail="Vous ne pouvez pas vous bannir vous-même.")
    user.is_banned = True  # type: ignore[assignment]
    await _audit(db, admin, "user.ban", "user", user_id, _get_ip(request), extra={"reason": body.reason})
    await db.commit()
    return {"detail": f"Utilisateur {user_id} banni. Raison : {body.reason}"}


@router.patch("/users/{user_id}/unban", status_code=status.HTTP_200_OK)
async def unban_user(
    user_id: uuid.UUID, request: Request,
    db: AsyncSession = Depends(get_db), admin: User = Depends(require_admin),
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
    user_id: uuid.UUID, request: Request,
    db: AsyncSession = Depends(get_db), admin: User = Depends(require_admin),
):
    user = await db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="Utilisateur introuvable.")
    user.is_admin = True  # type: ignore[assignment]
    await _audit(db, admin, "user.promote", "user", user_id, _get_ip(request))
    await db.commit()
    return {"detail": f"Utilisateur {user_id} promu administrateur."}


@router.get("/users/{user_id}/sessions", response_model=list[ConnectionLogRead])
async def get_user_sessions(
    user_id: uuid.UUID,
    limit: int = Query(100, le=500),
    since_days: int = Query(30, ge=1, le=365),
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    """
    Historique complet des connexions d'un utilisateur.
    Retourne : IP, device, méthode auth, statut, horodatage.
    Utile pour détecter des connexions suspectes ou répondre à une réquisition.
    """
    user = await db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="Utilisateur introuvable.")
    since = datetime.now(timezone.utc) - timedelta(days=since_days)
    logs = (await db.execute(
        select(ConnectionLog)
        .where(ConnectionLog.user_id == user_id, ConnectionLog.created_at >= since)
        .order_by(ConnectionLog.created_at.desc())
        .limit(limit)
    )).scalars().all()
    return logs


@router.get("/users/{user_id}/export")
async def export_user_data(
    user_id: uuid.UUID,
    request: Request,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin),
):
    """
    Export légal complet d'un utilisateur (CPDP / réquisition judiciaire).
    Retourne un fichier JSON contenant :
    - Informations de profil
    - Toutes les déclarations
    - Tous les matchs
    - Historique des connexions (IP, device, horodatage)
    - Signalements émis et reçus
    Format JSON signé par l'ID de l'admin requérant.
    """
    user = await db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="Utilisateur introuvable.")

    # Déclarations
    decls = (await db.execute(select(Declaration).where(Declaration.user_id == user_id))).scalars().all()
    # Matchs
    matches = (await db.execute(
        select(Match).where(or_(Match.user_found_id == user_id, Match.user_lost_id == user_id))
    )).scalars().all()
    # Connexions (120 derniers jours)
    sessions = (await db.execute(
        select(ConnectionLog)
        .where(ConnectionLog.user_id == user_id)
        .order_by(ConnectionLog.created_at.desc())
        .limit(1000)
    )).scalars().all()
    # Signalements
    reports_emitted = (await db.execute(select(Report).where(Report.reporter_id == user_id))).scalars().all()
    reports_received = (await db.execute(select(Report).where(Report.reported_id == user_id))).scalars().all()

    payload = {
        "export_metadata": {
            "generated_at": datetime.now(timezone.utc).isoformat(),
            "requested_by_admin": str(admin.id),
            "subject_user_id": str(user_id),
            "legal_basis": "CPDP Cameroun / Réquisition judiciaire",
        },
        "profile": {
            "id": str(user.id),
            "phone_number": user.phone_number,
            "full_name": getattr(user, "full_name", None),
            "email": getattr(user, "email", None),
            "created_at": user.created_at.isoformat(),
            "is_banned": getattr(user, "is_banned", False),
            "score_reputation": getattr(user, "score_reputation", 0.0),
        },
        "declarations": [
            {
                "id": str(d.id), "document_type": d.document_type,
                "declaration_type": d.declaration_type, "status": d.status,
                "created_at": d.created_at.isoformat(),
            } for d in decls
        ],
        "matches": [
            {
                "id": str(m.id), "score": m.score, "status": m.status,
                "created_at": m.created_at.isoformat(),
            } for m in matches
        ],
        "connection_history": [
            {
                "id": str(s.id), "ip_address": s.ip_address,
                "user_agent": s.user_agent, "device_id": s.device_id,
                "auth_method": s.auth_method, "status": s.status.value,
                "timestamp": s.created_at.isoformat(),
            } for s in sessions
        ],
        "reports_emitted": [
            {"id": str(r.id), "reason": r.reason.value, "status": r.status.value, "created_at": r.created_at.isoformat()}
            for r in reports_emitted
        ],
        "reports_received": [
            {"id": str(r.id), "reason": r.reason.value, "status": r.status.value, "created_at": r.created_at.isoformat()}
            for r in reports_received
        ],
    }

    await _audit(db, admin, "user.legal_export", "user", user_id, _get_ip(request),
                 extra={"legal_basis": "CPDP"})
    await db.commit()

    json_bytes = json.dumps(payload, ensure_ascii=False, indent=2).encode("utf-8")
    filename = f"export_legal_{user_id}_{datetime.now(timezone.utc).strftime('%Y%m%d_%H%M%S')}.json"
    return StreamingResponse(
        iter([json_bytes]),
        media_type="application/json",
        headers={"Content-Disposition": f"attachment; filename={filename}"},
    )


# ─────────────────────────────────────────────────────────────────────────────
# MODÉRATION DÉCLARATIONS
# ─────────────────────────────────────────────────────────────────────────────

@router.get("/declarations", response_model=list[DeclarationAdminRead])
async def list_all_declarations(
    page: int = Query(1, ge=1), per_page: int = Query(50, ge=1, le=100),
    flagged_only: bool = False,
    db: AsyncSession = Depends(get_db), _admin: User = Depends(require_admin),
):
    q = select(Declaration).order_by(Declaration.created_at.desc())
    if flagged_only:
        q = q.where(Declaration.is_flagged == True)  # noqa
    q = q.offset((page - 1) * per_page).limit(per_page)
    return (await db.execute(q)).scalars().all()


@router.delete("/declarations/{declaration_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_declaration(
    declaration_id: uuid.UUID, request: Request,
    db: AsyncSession = Depends(get_db), admin: User = Depends(require_admin),
):
    decl = await db.get(Declaration, declaration_id)
    if not decl:
        raise HTTPException(status_code=404, detail="Déclaration introuvable.")
    await _audit(db, admin, "declaration.delete", "declaration", declaration_id, _get_ip(request),
                 extra={"document_type": decl.document_type, "user_id": str(decl.user_id)})
    await db.delete(decl)
    await db.commit()


@router.patch("/declarations/{declaration_id}/flag")
async def flag_declaration(
    declaration_id: uuid.UUID, request: Request,
    db: AsyncSession = Depends(get_db), admin: User = Depends(require_admin),
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
    file: UploadFile = File(...), request: Request = None,
    db: AsyncSession = Depends(get_db), admin: User = Depends(require_admin),
):
    if file.content_type not in ("text/csv", "application/csv", "text/plain"):
        raise HTTPException(status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE, detail="Seuls les fichiers CSV sont acceptés.")
    content = (await file.read()).decode("utf-8", errors="replace")
    reader = csv.DictReader(io.StringIO(content))
    required_fields = {"document_type", "owner_name"}
    rows_created = 0
    errors = []
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
                 extra={"rows_created": rows_created, "errors_count": len(errors)})
    await db.commit()
    return {"rows_created": rows_created, "errors": errors}


@router.get("/export/declarations")
async def export_declarations_csv(
    db: AsyncSession = Depends(get_db), _admin: User = Depends(require_admin),
):
    declarations = (await db.execute(select(Declaration).order_by(Declaration.created_at.desc()))).scalars().all()
    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow(["id", "user_id", "document_type", "declaration_type", "status", "is_flagged", "created_at", "location_description"])
    for d in declarations:
        writer.writerow([str(d.id), str(d.user_id), d.document_type, d.declaration_type, d.status,
                         getattr(d, "is_flagged", False), d.created_at.isoformat(), getattr(d, "location_description", "")])
    output.seek(0)
    return StreamingResponse(iter([output.getvalue()]), media_type="text/csv",
                             headers={"Content-Disposition": "attachment; filename=declarations_export.csv"})


# ─────────────────────────────────────────────────────────────────────────────
# MATCHS & RESTITUTIONS
# ─────────────────────────────────────────────────────────────────────────────

@router.get("/matches", response_model=list[MatchAdminRead])
async def list_all_matches(
    page: int = Query(1, ge=1), per_page: int = Query(50, ge=1, le=100),
    status_filter: Optional[str] = Query(None, alias="status"),
    db: AsyncSession = Depends(get_db), _admin: User = Depends(require_admin),
):
    q = select(Match).order_by(Match.created_at.desc())
    if status_filter:
        q = q.where(Match.status == status_filter)
    q = q.offset((page - 1) * per_page).limit(per_page)
    return (await db.execute(q)).scalars().all()


@router.get("/restitutions", response_model=list[RestitutionAdminRead])
async def list_all_restitutions(
    page: int = Query(1, ge=1), per_page: int = Query(50, ge=1, le=100),
    status_filter: Optional[str] = Query(None, alias="status"),
    db: AsyncSession = Depends(get_db), _admin: User = Depends(require_admin),
):
    q = select(Restitution).order_by(Restitution.created_at.desc())
    if status_filter:
        q = q.where(Restitution.status == status_filter)
    q = q.offset((page - 1) * per_page).limit(per_page)
    return (await db.execute(q)).scalars().all()


# ─────────────────────────────────────────────────────────────────────────────
# ZONES CERTIFIÉES
# ─────────────────────────────────────────────────────────────────────────────

@router.post("/zones", response_model=ZoneRead, status_code=status.HTTP_201_CREATED)
async def create_zone(
    body: ZoneCreate, request: Request,
    db: AsyncSession = Depends(get_db), admin: User = Depends(require_admin),
):
    zone = Zone(id=uuid.uuid4(), name=body.name, zone_type=body.zone_type,
                latitude=body.latitude, longitude=body.longitude,
                address=body.address, institution_id=body.institution_id, is_certified=body.is_certified)
    db.add(zone)
    await _audit(db, admin, "zone.create", "zone", zone.id, _get_ip(request), extra={"name": zone.name})
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
    await _audit(db, admin, "zone.update", "zone", zone_id, _get_ip(request), extra=changes)
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
    await _audit(db, admin, "zone.delete", "zone", zone_id, _get_ip(request), extra={"name": zone.name})
    await db.delete(zone)
    await db.commit()


# ─────────────────────────────────────────────────────────────────────────────
# AUDIT LOGS
# ─────────────────────────────────────────────────────────────────────────────

@router.get("/audit-logs", response_model=list[AuditLogRead])
async def list_audit_logs(
    page: int = Query(1, ge=1), per_page: int = Query(50, ge=1, le=200),
    action_type: Optional[str] = None,
    admin_id: Optional[uuid.UUID] = None,
    since_days: int = Query(7, ge=1, le=365),
    db: AsyncSession = Depends(get_db), _admin: User = Depends(require_admin),
):
    since = datetime.now(timezone.utc) - timedelta(days=since_days)
    q = (select(AuditLog).where(AuditLog.created_at >= since).order_by(AuditLog.created_at.desc()))
    if action_type:
        q = q.where(AuditLog.action_type == action_type)
    if admin_id:
        q = q.where(AuditLog.admin_id == admin_id)
    q = q.offset((page - 1) * per_page).limit(per_page)
    return (await db.execute(q)).scalars().all()
