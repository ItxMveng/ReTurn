import asyncio
import json
from collections import defaultdict

from fastapi import WebSocket

# In-memory map: match_id (str) → set of connected WebSockets
_connections: dict[str, set[WebSocket]] = defaultdict(set)


def register(match_id: str, ws: WebSocket) -> None:
    _connections[match_id].add(ws)


def unregister(match_id: str, ws: WebSocket) -> None:
    _connections[match_id].discard(ws)
    if not _connections[match_id]:
        del _connections[match_id]


async def broadcast(match_id: str, payload: str) -> None:
    dead: set[WebSocket] = set()
    for ws in list(_connections.get(match_id, [])):
        try:
            await ws.send_text(payload)
        except Exception:
            dead.add(ws)
    for ws in dead:
        unregister(match_id, ws)


async def redis_subscriber(redis_url: str) -> None:
    """
    Background task: subscribe to all match:* channels on Redis
    and fan-out messages to connected WebSocket clients.
    """
    from redis.asyncio import from_url

    pubsub_client = from_url(redis_url, decode_responses=True)
    pubsub = pubsub_client.pubsub()
    await pubsub.psubscribe("match:*")

    async for raw in pubsub.listen():
        if raw["type"] != "pmessage":
            continue
        channel: str = raw["channel"]
        match_id = channel.removeprefix("match:")
        data: str = raw["data"]
        await broadcast(match_id, data)
