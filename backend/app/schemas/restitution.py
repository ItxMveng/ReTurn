import uuid
from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field

RestitutionStatus = Literal["pending", "in_progress", "completed", "cancelled"]


class RestitutionRead(BaseModel):
    id: uuid.UUID
    match_id: uuid.UUID
    meeting_location: str | None
    meeting_latitude: float | None
    meeting_longitude: float | None
    proof_photos: list[str]
    status: str
    handoff_confirmed_by_owner: bool = False
    handoff_confirmed_by_finder: bool = False
    rating_by_owner: int | None
    rating_by_finder: int | None
    comment_by_owner: str | None = None
    comment_by_finder: str | None = None
    completed_at: datetime | None
    created_at: datetime

    model_config = {"from_attributes": True}


class RestitutionUpdate(BaseModel):
    meeting_location: str | None = None
    meeting_latitude: float | None = None
    meeting_longitude: float | None = None
    status: RestitutionStatus | None = None


class RestitutionRating(BaseModel):
    """Submit a post-restitution rating (1-5 stars) + optional comment."""
    rating: int = Field(..., ge=1, le=5)
    comment: str | None = Field(None, max_length=140)
