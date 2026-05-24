import enum
import uuid
from datetime import datetime

from sqlalchemy import DateTime, Enum, ForeignKey, String, Text, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class ReportReason(str, enum.Enum):
    FRAUD = "fraud"                     # Tentative d'escroquerie
    HARASSMENT = "harassment"           # Harcèlement / insultes
    FAKE_DOCUMENT = "fake_document"     # Document falsifié
    IDENTITY_THEFT = "identity_theft"   # Usurpation d'identité
    INAPPROPRIATE = "inappropriate"     # Contenu inapproprié
    OTHER = "other"                     # Autre


class ReportStatus(str, enum.Enum):
    PENDING = "pending"         # En attente de traitement
    REVIEWED = "reviewed"       # En cours d'examen
    RESOLVED = "resolved"       # Résolu
    REJECTED = "rejected"       # Rejeté (signalement non fondé)


class Report(Base):
    __tablename__ = "reports"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    match_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("matches.id", ondelete="CASCADE"), nullable=False, index=True
    )
    reporter_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    reported_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    reason: Mapped[ReportReason] = mapped_column(
        Enum(ReportReason), nullable=False
    )
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    screenshot_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    status: Mapped[ReportStatus] = mapped_column(
        Enum(ReportStatus), default=ReportStatus.PENDING, nullable=False, index=True
    )
    admin_note: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    resolved_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    # Relations
    reporter = relationship("User", foreign_keys=[reporter_id])
    reported = relationship("User", foreign_keys=[reported_id])
