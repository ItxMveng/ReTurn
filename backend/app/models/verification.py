import uuid
from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base

# status: "pending" | "approved" | "rejected"
# verification_level (F-30, adaptatif selon le score du match) :
#   1 — Rapide    (score >= 0.75)  : nom + date de naissance, auto-approbation
#   2 — Standard  (0.50 - 0.74)    : + selfie, auto-approbation
#   3 — Renforcé  (0.45 - 0.49)    : + numéro doc + photo du document, revue admin


class IdentityVerification(Base):
    __tablename__ = "identity_verifications"
    __table_args__ = {"schema": "docretour"}

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    match_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("docretour.matches.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("docretour.users.id", ondelete="CASCADE"),
        nullable=False,
    )
    selfie_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    # Photo du document exigée au niveau 3 (revue admin).
    doc_photo_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    status: Mapped[str] = mapped_column(
        String(20), default="pending", nullable=False
    )
    verification_level: Mapped[int] = mapped_column(
        Integer, default=1, nullable=False, server_default="1"
    )
    # Questions de contrôle réussies (preuve de connaissance du document).
    questions_passed: Mapped[bool] = mapped_column(
        Boolean, default=False, nullable=False
    )
    # Revue admin (niveau 3) : motif du rejet éventuel + horodatage.
    rejection_reason: Mapped[str | None] = mapped_column(String(300), nullable=True)
    reviewed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
