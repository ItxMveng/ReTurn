import uuid
from datetime import datetime, date

from pydantic import BaseModel


class UserCreate(BaseModel):
    phone_number: str
    full_name: str = ""


class UserRead(BaseModel):
    id: uuid.UUID
    phone_number: str
    email: str | None = None
    full_name: str
    date_of_birth: date | None = None
    national_id_number: str | None = None
    gender: str | None = None
    city: str | None = None
    region: str | None = None
    address: str | None = None
    avatar_url: str | None = None
    score_reputation: float
    is_active: bool
    is_verified: bool
    is_profile_complete: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class UserUpdate(BaseModel):
    full_name: str | None = None
    date_of_birth: date | None = None
    national_id_number: str | None = None
    gender: str | None = None
    city: str | None = None
    region: str | None = None
    address: str | None = None
    fcm_token: str | None = None
