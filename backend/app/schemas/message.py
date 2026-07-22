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


class ConversationRead(BaseModel):
    """Une conversation = un match. Format attendu par l'app mobile."""

    room_id: str
    other_user_name: str
    other_user_avatar: str | None = None
    last_message: str | None = None
    last_at: str | None = None
    unread: int = 0


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
