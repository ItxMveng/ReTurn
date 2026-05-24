"""Endpoints signalements : utilisateur + admin."""
import uuid

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.dependencies import get_current_user, require_admin
from app.models.report import ReportStatus
from app.models.user import User
from app.schemas.report import ReportCreate, ReportRead, ReportUpdate
from app.services import report_service

router = APIRouter(tags=["reports"])


# ── Utilisateur : lire ses propres signalements ───────────────────────────────

@router.get("/my-reports", response_model=list[ReportRead])
async def get_my_reports(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Retourne les signalements émis par l'utilisateur connecté."""
    from sqlalchemy import select
    from app.models.report import Report
    result = await db.execute(
        select(Report)
        .where(Report.reporter_id == current_user.id)
        .order_by(Report.created_at.desc())
    )
    return result.scalars().all()


# ── Admin : liste et résolution ───────────────────────────────────────────────

@router.get("/admin/reports", response_model=list[ReportRead])
async def admin_list_reports(
    status: ReportStatus | None = Query(None, description="Filtrer par statut"),
    limit: int = Query(50, le=100),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    """[Admin] Liste paginée des signalements."""
    return await report_service.list_reports(db, status=status, limit=limit, offset=offset)


@router.patch("/admin/reports/{report_id}", response_model=ReportRead)
async def admin_update_report(
    report_id: uuid.UUID,
    payload: ReportUpdate,
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    """[Admin] Met à jour le statut d'un signalement (résoudre / rejeter)."""
    report = await report_service.get_report(db, report_id)
    if not report:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Signalement introuvable",
        )
    return await report_service.update_report(db, report, payload)
