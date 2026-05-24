"""
Modèle AuditLog — trace toutes les actions sensibles de la plateforme.

Conformité CDC §11.1 : "Tous les accès aux données sensibles sont loggés
avec timestamp, IP, user_id."

action_type exemples :
  user.ban | user.unban | user.promote
  declaration.delete | declaration.flag
  zone.create | zone.delete | zone.update
  match.admin_close
  restitution.admin_cancel
"""
import uuid
from datetime import datetime
from typing import Optional

from sqlalchemy import DateTime, ForeignKey, JSON, String, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class AuditLog(Base):
    __tablename__ = "audit_logs"
    __table_args__ = {"schema": "docretour"}

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    # L'admin qui a effectué l'action (NULL = système)
    admin_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("docretour.users.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    action_type: Mapped[str] = mapped_column(
        String(80), nullable=False, index=True
    )  # ex: "user.ban", "declaration.delete"
    target_type: Mapped[Optional[str]] = mapped_column(
        String(50), nullable=True
    )  # ex: "user", "declaration", "zone"
    target_id: Mapped[Optional[str]] = mapped_column(
        String(100), nullable=True
    )  # UUID stringifié de la ressource affectée
    ip_address: Mapped[Optional[str]] = mapped_column(
        String(45), nullable=True
    )  # IPv4 ou IPv6
    extra: Mapped[Optional[dict]] = mapped_column(
        JSON, nullable=True
    )  # payload libre (raison de ban, ancienne valeur, etc.)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), index=True
    )

    admin: Mapped[Optional["User"]] = relationship(  # noqa: F821
        "User", foreign_keys=[admin_id]
    )
