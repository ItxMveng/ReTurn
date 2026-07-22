"""Lecture/écriture de la configuration dynamique (table app_config).

Les valeurs par défaut vivent ici ; la table ne contient que les overrides
posés par un admin via PATCH /admin/config.
"""
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.app_config import AppConfig

DEFAULTS: dict[str, float] = {
    "active_declarations_limit": 3.0,  # F-15 anti-fraude
    "min_score": 0.45,                 # seuil de création d'un Match
    "geo_max_km": 50.0,                # rayon au-delà duquel le score géo = 0
}


async def get_config(db: AsyncSession) -> dict[str, float]:
    rows = (await db.execute(select(AppConfig))).scalars().all()
    config = dict(DEFAULTS)
    for row in rows:
        if row.key in config:
            config[row.key] = row.value
    return config


async def get_value(db: AsyncSession, key: str) -> float:
    config = await get_config(db)
    return config[key]


async def set_config(db: AsyncSession, updates: dict[str, float]) -> dict[str, float]:
    for key, value in updates.items():
        if key not in DEFAULTS or value is None:
            continue
        row = await db.get(AppConfig, key)
        if row is not None:
            row.value = float(value)
            db.add(row)
        else:
            db.add(AppConfig(key=key, value=float(value)))
    await db.flush()
    return await get_config(db)
