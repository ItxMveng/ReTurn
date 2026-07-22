import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field

from app.models.report import ReportReason, ReportStatus


class ReportCreate(BaseModel):
    # Optionnel : si absent, le serveur le déduit de l'autre participant du match.
    reported_id: Optional[uuid.UUID] = Field(
        None, description="ID de l'utilisateur signalé (déduit si absent)"
    )
    reason: ReportReason = Field(..., description="Motif du signalement")
    description: Optional[str] = Field(
        None, max_length=1000, description="Description détaillée (optionnel)"
    )
    screenshot_url: Optional[str] = Field(
        None, description="URL d'une capture d'écran comme preuve"
    )


class ReportRead(BaseModel):
    id: uuid.UUID
    match_id: uuid.UUID
    reporter_id: uuid.UUID
    reported_id: uuid.UUID
    # Libellés lisibles renseignés par l'API admin (nom ou téléphone).
    reporter_name: Optional[str] = None
    reported_name: Optional[str] = None
    reason: ReportReason
    description: Optional[str]
    screenshot_url: Optional[str]
    status: ReportStatus
    admin_note: Optional[str]
    created_at: datetime
    resolved_at: Optional[datetime]

    model_config = {"from_attributes": True}


class ReportUpdate(BaseModel):
    """Réservé à l'admin pour mettre à jour le statut d'un signalement."""
    status: ReportStatus
    admin_note: Optional[str] = Field(None, max_length=2000)
