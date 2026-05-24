"""Modèle ConnectionLog — traçabilité légale des connexions (CPDP / ANSSI)."""
import enum
import uuid
from datetime import datetime

from sqlalchemy import DateTime, Enum, ForeignKey, String, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class ConnectionStatus(str, enum.Enum):
    SUCCESS = "success"       # Connexion réussie
    FAILED = "failed"         # OTP invalide / mauvais mot de passe
    BANNED = "banned"         # Tentative depuis un compte banni
    SUSPICIOUS = "suspicious" # IP suspecte / trop de tentatives


class ConnectionLog(Base):
    """Enregistre chaque tentative de connexion pour traçabilité légale."""
    __tablename__ = "connection_logs"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    # NULL si l'utilisateur n'existe pas encore (tentative avec numéro inconnu)
    user_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    phone_number: Mapped[str | None] = mapped_column(String(20), nullable=True, index=True)
    ip_address: Mapped[str | None] = mapped_column(String(45), nullable=True, index=True)  # IPv6 max 45 chars
    user_agent: Mapped[str | None] = mapped_column(String(500), nullable=True)
    device_id: Mapped[str | None] = mapped_column(String(200), nullable=True)
    auth_method: Mapped[str] = mapped_column(String(20), default="otp", nullable=False)  # otp | firebase | refresh
    status: Mapped[ConnectionStatus] = mapped_column(
        Enum(ConnectionStatus), nullable=False, default=ConnectionStatus.SUCCESS, index=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False, index=True
    )

    # Relation vers l'utilisateur (optionnelle)
    user = relationship("User", foreign_keys=[user_id])
