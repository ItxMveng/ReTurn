import uuid
from datetime import datetime
from typing import Literal

from pydantic import BaseModel, field_validator

DOCUMENT_TYPES = [
    "cni",
    "passport",
    "driving_license",
    "vehicle_registration",
    "birth_certificate",
    "diploma",
    "other",
]

DeclarationType = Literal["found", "lost"]
StatusType = Literal["active", "matched", "closed"]


class DeclarationCreate(BaseModel):
    declaration_type: DeclarationType
    document_type: str
    document_number: str | None = None
    owner_name: str | None = None
    description: str | None = None
    latitude: float | None = None
    longitude: float | None = None
    location_description: str | None = None

    @field_validator("document_type")
    @classmethod
    def validate_doc_type(cls, v: str) -> str:
        if v not in DOCUMENT_TYPES:
            raise ValueError(f"document_type must be one of {DOCUMENT_TYPES}")
        return v


class DeclarationUpdate(BaseModel):
    document_number: str | None = None
    owner_name: str | None = None
    description: str | None = None
    location_description: str | None = None
    status: StatusType | None = None


class DeclarationRead(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    declaration_type: str
    document_type: str
    document_number: str | None
    owner_name: str | None
    description: str | None
    latitude: float | None
    longitude: float | None
    location_description: str | None
    photo_urls: list[str]
    status: str
    created_at: datetime

    model_config = {"from_attributes": True}
