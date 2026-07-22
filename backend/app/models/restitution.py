"""Restitution model — tracks the full handoff lifecycle (F-33).

A Restitution is created when both parties confirm a Match.
It records the agreed meeting point, the actual handoff, and stores
proof photos uploaded by both parties.
"""
import uuid
from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, JSON, String, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base

# status: "pending" | "in_progress" | "completed" | "cancelled"


class Restitution(Base):
    __tablename__ = "restitutions"
    __table_args__ = {"schema": "docretour"}

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    match_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("docretour.matches.id", ondelete="CASCADE"),
        nullable=False,
        unique=True,  # one restitution per match
        index=True,
    )
    # Agreed meeting point
    meeting_location: Mapped[str | None] = mapped_column(String(300), nullable=True)
    meeting_latitude: Mapped[float | None] = mapped_column(
        __import__("sqlalchemy").Float, nullable=True
    )
    meeting_longitude: Mapped[float | None] = mapped_column(
        __import__("sqlalchemy").Float, nullable=True
    )
    # Proof photos uploaded by finder and owner respectively
    proof_photos: Mapped[list] = mapped_column(
        JSON, nullable=False, default=list
    )  # list of MinIO URLs
    status: Mapped[str] = mapped_column(
        String(20), default="pending", nullable=False, index=True
    )
    # Double validation de la remise physique (F-33) — chaque partie confirme dans l'app
    handoff_confirmed_by_owner: Mapped[bool] = mapped_column(
        __import__("sqlalchemy").Boolean, default=False, nullable=False
    )
    handoff_confirmed_by_finder: Mapped[bool] = mapped_column(
        __import__("sqlalchemy").Boolean, default=False, nullable=False
    )
    # Ratings left after handoff (1-5 stars each) + commentaire optionnel
    rating_by_owner: Mapped[int | None] = mapped_column(
        __import__("sqlalchemy").Integer, nullable=True
    )
    rating_by_finder: Mapped[int | None] = mapped_column(
        __import__("sqlalchemy").Integer, nullable=True
    )
    comment_by_owner: Mapped[str | None] = mapped_column(
        String(140), nullable=True
    )
    comment_by_finder: Mapped[str | None] = mapped_column(
        String(140), nullable=True
    )

    completed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    match: Mapped["Match"] = relationship("Match", foreign_keys=[match_id])  # noqa: F821
