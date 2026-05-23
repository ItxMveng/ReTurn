import uuid
from datetime import datetime

from sqlalchemy import DateTime, Float, ForeignKey, JSON, String, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base

# declaration_type : "found" | "lost"
# status           : "active" | "matched" | "closed"


class Declaration(Base):
    __tablename__ = "declarations"
    __table_args__ = {"schema": "docretour"}

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("docretour.users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    declaration_type: Mapped[str] = mapped_column(String(10), nullable=False)
    document_type: Mapped[str] = mapped_column(String(30), nullable=False, index=True)
    document_number: Mapped[str | None] = mapped_column(
        String(50), nullable=True, index=True
    )
    owner_name: Mapped[str | None] = mapped_column(String(100), nullable=True)
    description: Mapped[str | None] = mapped_column(String(500), nullable=True)
    latitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    longitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    location_description: Mapped[str | None] = mapped_column(
        String(200), nullable=True
    )
    photo_urls: Mapped[list] = mapped_column(JSON, nullable=False, default=list)
    status: Mapped[str] = mapped_column(
        String(20), default="active", nullable=False, index=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    user: Mapped["User"] = relationship("User", back_populates="declarations")  # noqa: F821
