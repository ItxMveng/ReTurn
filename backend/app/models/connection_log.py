"""Modèle de traçabilité des connexions utilisateur.

Chaque tentative de connexion (OTP, Firebase) est enregistrée ici.
Permet de répondre aux réquisitions judiciaires et exigences CPDP.
"""
import enum
import uuid
from datetime import datetime

from sqlalchemy import DateTime, Enum, ForeignKey, String, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class ConnectionStatus(str, enum.Enum):
    SUCCESS = "success"       # Connexion réussie
    FAILED = "failed"         # OTP invalide / token Firebase rejeté
    BANNED = "banned"         # Tentative d'un compte banni


class ConnectionLog(Base):
    __tablename__ = "connection_logs"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
        comment="NULL si l'utilisateur n'existe pas encore (1ère tentative)",
    )
    phone_number: Mapped[str | None] = mapped_column(
        String(30), nullable=True, index=True,
        comment="Numéro composé (pour les tentatives sans user_id)",
    )
    ip_address: Mapped[str | None] = mapped_column(
        String(45), nullable=True, index=True,
        comment="IPv4 ou IPv6 (max 45 chars pour IPv6)",
    )
    user_agent: Mapped[str | None] = mapped_column(
        String(500), nullable=True,
        comment="User-Agent HTTP : modèle appareil, OS, version app",
    )
    device_id: Mapped[str | None] = mapped_column(
        String(200), nullable=True,
        comment="Identifiant matériel transmis par le client Flutter",
    )
    auth_method: Mapped[str] = mapped_column(
        String(20), nullable=False, default="otp",
        comment="otp | firebase | refresh",
    )
    status: Mapped[ConnectionStatus] = mapped_column(
        Enum(ConnectionStatus), nullable=False, default=ConnectionStatus.SUCCESS, index=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False, index=True
    )

    # Relation optionnelle (lecture seule)
    user = relationship("User", foreign_keys=[user_id], lazy="select")
