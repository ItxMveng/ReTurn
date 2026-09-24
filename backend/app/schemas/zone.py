import uuid

from pydantic import BaseModel


class ZonePublic(BaseModel):
    """Zone de récupération certifiée, exposée aux utilisateurs (F-32)."""

    id: uuid.UUID
    name: str
    zone_type: str
    address: str
    country_code: str | None = None
    latitude: float
    longitude: float
    is_certified: bool

    model_config = {"from_attributes": True}
