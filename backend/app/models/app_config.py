"""Configuration dynamique de la plateforme (modifiable via /admin/config).

Stocke des paramètres numériques clé/valeur : limite de déclarations actives,
score minimum de matching, rayon géographique maximum.
"""
from datetime import datetime

from sqlalchemy import DateTime, Float, String, func
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class AppConfig(Base):
    __tablename__ = "app_config"
    __table_args__ = {"schema": "docretour"}

    key: Mapped[str] = mapped_column(String(50), primary_key=True)
    value: Mapped[float] = mapped_column(Float, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )
