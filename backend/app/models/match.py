import uuid
from datetime import datetime

from sqlalchemy import Boolean, DateTime, Float, ForeignKey, String, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base

# status: "pending" | "confirmed" | "ignored" | "closed"


class Match(Base):
    __tablename__ = "matches"
    __table_args__ = {"schema": "docretour"}

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    declaration_found_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("docretour.declarations.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    declaration_lost_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("docretour.declarations.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    user_found_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("docretour.users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    user_lost_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("docretour.users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    score: Mapped[float] = mapped_column(Float, nullable=False)
    status: Mapped[str] = mapped_column(
        String(20), default="pending", nullable=False, index=True
    )
    # Double confirmation (F-33): both parties must confirm to trigger restitution
    confirmed_by_owner: Mapped[bool] = mapped_column(
        Boolean, default=False, nullable=False
    )
    confirmed_by_finder: Mapped[bool] = mapped_column(
        Boolean, default=False, nullable=False
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    declaration_found: Mapped["Declaration"] = relationship(  # noqa: F821
        "Declaration", foreign_keys=[declaration_found_id]
    )
    declaration_lost: Mapped["Declaration"] = relationship(  # noqa: F821
        "Declaration", foreign_keys=[declaration_lost_id]
    )
