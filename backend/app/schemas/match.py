import uuid
from datetime import datetime
from typing import Literal

from pydantic import BaseModel

from app.schemas.declaration import DeclarationRead

MatchStatus = Literal["pending", "confirmed", "ignored", "closed"]


class MatchRead(BaseModel):
    id: uuid.UUID
    declaration_found_id: uuid.UUID
    declaration_lost_id: uuid.UUID
    user_found_id: uuid.UUID
    user_lost_id: uuid.UUID
    score: float
    status: str
    confirmed_by_owner: bool
    confirmed_by_finder: bool
    created_at: datetime
    declaration_found: DeclarationRead | None = None
    declaration_lost: DeclarationRead | None = None

    model_config = {"from_attributes": True}


class MatchAction(BaseModel):
    action: Literal["confirmed", "ignored"]


class MatchConfirmResponse(BaseModel):
    """Returned after a confirm action — includes restitution_id if both sides confirmed."""
    match_id: uuid.UUID
    confirmed_by_owner: bool
    confirmed_by_finder: bool
    both_confirmed: bool
    restitution_id: uuid.UUID | None = None

    model_config = {"from_attributes": True}
