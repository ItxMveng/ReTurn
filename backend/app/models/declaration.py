import uuid
from datetime import datetime, date

from sqlalchemy import Date, DateTime, Float, ForeignKey, JSON, String, func
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
    # Pays (ISO 3166-1 alpha-2). Le matching ne rapproche que des déclarations
    # du même pays lorsqu'il est renseigné.
    country_code: Mapped[str | None] = mapped_column(
        String(2), nullable=True, index=True
    )
    photo_urls: Mapped[list] = mapped_column(JSON, nullable=False, default=list)
    status: Mapped[str] = mapped_column(
        String(20), default="active", nullable=False, index=True
    )
    # Dossier multi-documents : plusieurs déclarations créées en une fois
    # (ex. portefeuille avec CNI + permis) partagent le même group_id.
    # Un dossier compte pour UNE seule déclaration dans la limite F-15.
    group_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), nullable=True, index=True
    )
    # Date of the event (loss date for "lost", find date for "found")
    # Used for temporal coherence in matching: found_date >= lost_date
    event_date: Mapped[date | None] = mapped_column(Date, nullable=True, index=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    user: Mapped["User"] = relationship("User", back_populates="declarations")  # noqa: F821
