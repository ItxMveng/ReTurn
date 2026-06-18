import re
import uuid
from datetime import datetime, date

from pydantic import BaseModel, field_validator, model_validator

_PHONE_RE = re.compile(r"^\+?[0-9]{9,15}$")
_EMAIL_RE = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")


class UserCreate(BaseModel):
    phone_number: str | None = None
    full_name: str = ""


class UserRead(BaseModel):
    id: uuid.UUID
    phone_number: str | None = None
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
    email: str | None = None
    phone_number: str | None = None
    date_of_birth: date | None = None
    national_id_number: str | None = None
    gender: str | None = None
    city: str | None = None
    region: str | None = None
    address: str | None = None
    fcm_token: str | None = None

    @field_validator("email")
    @classmethod
    def validate_email(cls, v: str | None) -> str | None:
        if v is None:
            return v
        v = v.strip().lower()
        if not _EMAIL_RE.match(v):
            raise ValueError("Adresse email invalide.")
        return v

    @field_validator("phone_number")
    @classmethod
    def validate_phone(cls, v: str | None) -> str | None:
        if v is None:
            return v
        v = v.strip()
        if not _PHONE_RE.match(v):
            raise ValueError("Numéro de téléphone invalide (format: +237XXXXXXXXX).")
        return v
