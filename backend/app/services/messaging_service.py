import json
import uuid
from datetime import datetime, timezone

from redis.asyncio import Redis
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.message import Message
from app.schemas.message import WsOutgoing

HISTORY_KEY_PREFIX = "chat:history:"
HISTORY_MAX = 100


def _serialize(msg: Message) -> str:
    return WsOutgoing(
        id=str(msg.id),
        match_id=str(msg.match_id),
        sender_id=str(msg.sender_id),
        content=msg.content,
        message_type=msg.message_type,
        created_at=msg.created_at.isoformat(),
        is_read=msg.is_read,
    ).model_dump_json()


async def save_message(
    db: AsyncSession,
    redis: Redis,
    match_id: uuid.UUID,
    sender_id: uuid.UUID,
    content: str,
    message_type: str = "text",
) -> Message:
    msg = Message(
        match_id=match_id,
        sender_id=sender_id,
        content=content,
        message_type=message_type,
    )
    db.add(msg)
    await db.flush()
    await db.refresh(msg)
    await db.commit()  # persist to DB

    serialized = _serialize(msg)
    key = f"{HISTORY_KEY_PREFIX}{match_id}"
    await redis.lpush(key, serialized)
    await redis.ltrim(key, 0, HISTORY_MAX - 1)

    # Publish to match channel for WebSocket broadcast
    await redis.publish(f"match:{match_id}", serialized)
    return msg


async def get_history(
    db: AsyncSession, match_id: uuid.UUID, limit: int = 50
) -> list[Message]:
    result = await db.execute(
        select(Message)
        .where(Message.match_id == match_id)
        .order_by(Message.created_at.asc())
        .limit(limit)
    )
    return list(result.scalars().all())


async def mark_read(
    db: AsyncSession, match_id: uuid.UUID, reader_id: uuid.UUID
) -> None:
    from sqlalchemy import update
    await db.execute(
        update(Message)
        .where(
            Message.match_id == match_id,
            Message.sender_id != reader_id,
            Message.is_read == False,  # noqa: E712
        )
        .values(is_read=True)
    )
