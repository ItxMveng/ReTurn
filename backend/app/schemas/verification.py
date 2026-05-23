import uuid
from datetime import datetime

from pydantic import BaseModel


class VerificationRead(BaseModel):
    id: uuid.UUID
    match_id: uuid.UUID
    user_id: uuid.UUID
    selfie_url: str | None
    status: str
    created_at: datetime

    model_config = {"from_attributes": True}
