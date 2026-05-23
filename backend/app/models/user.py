import uuid
from datetime import datetime, date

from typing import TYPE_CHECKING

from sqlalchemy import Boolean, DateTime, Date, String, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base

if TYPE_CHECKING:
    from app.models.declaration import Declaration


class User(Base):
    __tablename__ = "users"
    __table_args__ = {"schema": "docretour"}

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    firebase_uid: Mapped[str] = mapped_column(
        String(128), unique=True, index=True, nullable=True
    )
    phone_number: Mapped[str] = mapped_column(
        String(100), unique=True, index=True, nullable=False
    )
    email: Mapped[str | None] = mapped_column(
        String(254), unique=True, index=True, nullable=True
    )
    full_name: Mapped[str] = mapped_column(String(100), nullable=False, default="")

    # Personal info fields (required for lost declarations)
    date_of_birth: Mapped[date | None] = mapped_column(Date, nullable=True)
    national_id_number: Mapped[str | None] = mapped_column(String(50), nullable=True)
    gender: Mapped[str | None] = mapped_column(String(20), nullable=True)
    city: Mapped[str | None] = mapped_column(String(100), nullable=True)
    region: Mapped[str | None] = mapped_column(String(100), nullable=True)
    address: Mapped[str | None] = mapped_column(String(255), nullable=True)
    avatar_url: Mapped[str | None] = mapped_column(String(512), nullable=True)
    fcm_token: Mapped[str | None] = mapped_column(String(512), nullable=True)

    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    is_verified: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    declarations: Mapped[list["Declaration"]] = relationship(
        "Declaration", back_populates="user", cascade="all, delete-orphan"
    )

    @property
    def is_profile_complete(self) -> bool:
        # Required: full_name, date_of_birth, gender, city (place of birth)
        # Optional: national_id_number, region, address
        return bool(
            self.full_name
            and self.date_of_birth
            and self.gender
            and self.city
        )
