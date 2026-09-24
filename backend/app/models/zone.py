import uuid
from datetime import datetime, timezone
from typing import Optional

from sqlalchemy import Boolean, DateTime, Float, ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class Zone(Base):
    """Points de dépôt certifiés — commissariats, mairies, campus (F-32, F-43)."""
    __tablename__ = "zones_recuperation"
    __table_args__ = {"schema": "docretour"}

    id: Mapped[uuid.UUID] = mapped_column(
        primary_key=True, default=uuid.uuid4
    )
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    zone_type: Mapped[str] = mapped_column(
        String(50), nullable=False, comment="commissariat | mairie | campus | autre"
    )
    address: Mapped[str] = mapped_column(String(500), nullable=False)
    country_code: Mapped[Optional[str]] = mapped_column(
        String(2), nullable=True, index=True
    )
    latitude: Mapped[float]  = mapped_column(Float, nullable=False)
    longitude: Mapped[float] = mapped_column(Float, nullable=False)
    is_certified: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    institution_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        ForeignKey("docretour.users.id", ondelete="SET NULL"), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )
