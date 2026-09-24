"""Zones de récupération certifiées — accès lecture pour les utilisateurs (F-32)."""
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.countries import normalize_country_code
from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.models.zone import Zone
from app.schemas.zone import ZonePublic

router = APIRouter(prefix="/zones", tags=["zones"])


@router.get("/", response_model=list[ZonePublic])
async def list_zones(
    certified_only: bool = True,
    country: str | None = Query(
        None, description="ISO 3166-1 alpha-2 ; défaut : pays du profil (sinon tous)"
    ),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Liste des zones de récupération (commissariats, mairies, campus…)."""
    try:
        country_code = normalize_country_code(country) or current_user.country_code
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=str(exc)
        )
    stmt = select(Zone).order_by(Zone.name)
    if certified_only:
        stmt = stmt.where(Zone.is_certified == True)  # noqa: E712
    if country_code:
        stmt = stmt.where(Zone.country_code == country_code)
    result = await db.execute(stmt)
    return list(result.scalars().all())
