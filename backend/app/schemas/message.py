import uuid
from datetime import datetime

from pydantic import BaseModel


class MessageRead(BaseModel):
    id: uuid.UUID
    match_id: uuid.UUID
    sender_id: uuid.UUID
    content: str
    message_type: str
    is_read: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class WsIncoming(BaseModel):
    content: str
    message_type: str = "text"


class WsOutgoing(BaseModel):
    id: str
    match_id: str
    sender_id: str
    content: str
    message_type: str
    created_at: str
    is_read: bool = False
