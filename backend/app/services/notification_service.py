import json
import logging
import uuid
from datetime import datetime, timezone

import firebase_admin
from firebase_admin import messaging as fcm_messaging
from redis.asyncio import Redis

from app.core.config import settings

logger = logging.getLogger(__name__)

NOTIFICATION_KEY_PREFIX = "notifications:"
NOTIFICATION_TTL = 60 * 60 * 24 * 7  # 7 days

_DOC_TYPE_LABELS: dict[str, str] = {
    "cni": "Carte nationale d'identité",
    "passport": "Passeport",
    "driving_license": "Permis de conduire",
    "vehicle_registration": "Carte grise",
    "birth_certificate": "Acte de naissance",
    "diploma": "Diplôme",
    "other": "Document",
}


def _doc_label(doc_type: str) -> str:
    return _DOC_TYPE_LABELS.get(doc_type, "Document")


async def _send_fcm(
    token: str,
    title: str,
    body: str,
    data: dict[str, str],
) -> None:
    """Send a single FCM push. Silently skips if in mock mode or token is empty."""
    if settings.FIREBASE_MOCK_MODE or not token:
        return
    try:
        message = fcm_messaging.Message(
            notification=fcm_messaging.Notification(title=title, body=body),
            data=data,
            android=fcm_messaging.AndroidConfig(
                priority="high",
                notification=fcm_messaging.AndroidNotification(
                    sound="default",
                    channel_id="docretour_alerts",
                ),
            ),
            apns=fcm_messaging.APNSConfig(
                payload=fcm_messaging.APNSPayload(
                    aps=fcm_messaging.Aps(sound="default", badge=1)
                )
            ),
            token=token,
        )
        fcm_messaging.send(message)
    except fcm_messaging.UnregisteredError:
        logger.info("FCM token unregistered, will be cleaned up on next login.")
    except Exception as exc:
        logger.warning("FCM send failed: %s", exc)


async def push_notification(
    fcm_token: str,
    title: str,
    body: str,
    data: dict[str, str],
) -> None:
    """Wrapper public autour de _send_fcm, utilisé par report_service."""
    await _send_fcm(token=fcm_token, title=title, body=body, data=data)


async def push_match_notification(
    redis: Redis,
    user_id: uuid.UUID,
    match_id: uuid.UUID,
    match_score: float,
    document_type: str,
    fcm_token: str | None = None,
) -> None:
    payload = json.dumps(
        {
            "type": "match_found",
            "match_id": str(match_id),
            "score": round(match_score, 2),
            "document_type": document_type,
            "created_at": datetime.now(timezone.utc).isoformat(),
        }
    )
    key = f"{NOTIFICATION_KEY_PREFIX}{user_id}"
    await redis.lpush(key, payload)
    await redis.expire(key, NOTIFICATION_TTL)
    await redis.publish(f"user:{user_id}", payload)

    label = _doc_label(document_type)
    score_pct = int(round(match_score * 100))
    await _send_fcm(
        token=fcm_token or "",
        title="📄 Document correspondant trouvé !",
        body=f"Un {label} avec {score_pct}% de correspondance a été localisé.",
        data={
            "type": "match_found",
            "match_id": str(match_id),
            "document_type": document_type,
        },
    )


async def push_message_notification(
    fcm_token: str | None,
    match_id: uuid.UUID,
    sender_name: str,
    preview: str,
) -> None:
    """Push notification for a new chat message (sent when recipient is offline)."""
    await _send_fcm(
        token=fcm_token or "",
        title=f"💬 {sender_name}",
        body=preview[:80] if len(preview) > 80 else preview,
        data={
            "type": "new_message",
            "match_id": str(match_id),
        },
    )


async def get_pending_notifications(
    redis: Redis, user_id: uuid.UUID
) -> list[dict]:
    key = f"{NOTIFICATION_KEY_PREFIX}{user_id}"
    raw = await redis.lrange(key, 0, 49)
    return [json.loads(item) for item in raw]


async def clear_notifications(redis: Redis, user_id: uuid.UUID) -> None:
    await redis.delete(f"{NOTIFICATION_KEY_PREFIX}{user_id}")
