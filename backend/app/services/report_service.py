"""Service de gestion des signalements / litiges."""
import uuid
from datetime import datetime, timezone
from typing import Optional

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.models.report import Report, ReportStatus
from app.models.user import User
from app.schemas.report import ReportCreate, ReportUpdate
from app.services.notification_service import push_notification


ADMIN_FCM_TOKEN_KEY = "admin:fcm_token"  # clé Redis ou config


async def create_report(
    db: AsyncSession,
    match_id: uuid.UUID,
    reporter: User,
    payload: ReportCreate,
) -> Report:
    """Crée un signalement et notifie l'admin."""
    report = Report(
        match_id=match_id,
        reporter_id=reporter.id,
        reported_id=payload.reported_id,
        reason=payload.reason,
        description=payload.description,
        screenshot_url=payload.screenshot_url,
    )
    db.add(report)
    await db.commit()
    await db.refresh(report)

    # Notification FCM push vers l'admin
    await _notify_admin_fcm(report, reporter)

    return report


async def list_reports(
    db: AsyncSession,
    status: Optional[ReportStatus] = None,
    limit: int = 50,
    offset: int = 0,
) -> list[Report]:
    """Liste paginée des signalements (admin uniquement)."""
    q = select(Report).order_by(Report.created_at.desc())
    if status:
        q = q.where(Report.status == status)
    q = q.limit(limit).offset(offset)
    result = await db.execute(q)
    return list(result.scalars().all())


async def get_report(
    db: AsyncSession, report_id: uuid.UUID
) -> Optional[Report]:
    result = await db.execute(select(Report).where(Report.id == report_id))
    return result.scalar_one_or_none()


async def update_report(
    db: AsyncSession, report: Report, payload: ReportUpdate
) -> Report:
    """L'admin met à jour le statut d'un signalement."""
    report.status = payload.status
    if payload.admin_note:
        report.admin_note = payload.admin_note
    if payload.status in (ReportStatus.RESOLVED, ReportStatus.REJECTED):
        report.resolved_at = datetime.now(timezone.utc)
    await db.commit()
    await db.refresh(report)
    return report


async def _notify_admin_fcm(report: Report, reporter: User) -> None:
    """Envoie une notification FCM à l'admin et tente un email."""
    admin_token = getattr(settings, "ADMIN_FCM_TOKEN", None)
    reason_label = report.reason.value.replace("_", " ").capitalize()
    reporter_name = reporter.full_name or reporter.phone_number or "Utilisateur"

    if admin_token:
        await push_notification(
            fcm_token=admin_token,
            title="⚠️ Nouveau signalement",
            body=f"{reporter_name} a signalé un utilisateur — Motif : {reason_label}",
            data={
                "type": "admin_report",
                "report_id": str(report.id),
                "match_id": str(report.match_id),
                "reason": report.reason.value,
            },
        )
