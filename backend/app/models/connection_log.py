"""Modèle ConnectionLog — traçabilité légale des connexions utilisateur.

CDC §11.1 : "Tous les accès aux données sensibles sont loggés."
Obligatoire pour répondre aux réquisitions judiciaires (ANSSI Cameroun, tribunal).
"""
import enum
import uuid
from datetime import datetime

from sqlalchemy import DateTime, Enum, ForeignKey, String, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class ConnectionStatus(str, enum.Enum):
    SUCCESS = "success"   # Connexion réussie
    FAILED  = "failed"    # OTP invalide / token refusé
    BANNED  = "banned"    # Utilisateur banni a tenté de se connecter


class ConnectionLog(Base):
    __tablename__ = "connection_logs"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    # Peut être NULL si la connexion échoue avant identification
    user_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    phone_number: Mapped[str | None] = mapped_column(String(20), nullable=True)
    ip_address:   Mapped[str | None] = mapped_column(String(45), nullable=True)  # IPv6 max 45 chars
    user_agent:   Mapped[str | None] = mapped_column(String(512), nullable=True)
    device_id:    Mapped[str | None] = mapped_column(String(256), nullable=True)
    auth_method:  Mapped[str] = mapped_column(String(20), default="otp", nullable=False)
    status: Mapped[ConnectionStatus] = mapped_column(
        Enum(ConnectionStatus), nullable=False, index=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False, index=True
    )
