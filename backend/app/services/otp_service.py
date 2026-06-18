import random
import string

from fastapi import HTTPException, status
from redis.asyncio import Redis

OTP_TTL_SECONDS = 300         # 5 minutes
OTP_KEY_PREFIX = "otp:"
_RATE_REQ_PREFIX = "otp_req:"   # demandes par numéro
_RATE_VER_PREFIX = "otp_ver:"   # tentatives de vérification par numéro
_MAX_REQUESTS_PER_WINDOW = 3    # max 3 demandes / 10 min
_MAX_VERIFY_ATTEMPTS = 5        # max 5 tentatives / 10 min
_RATE_WINDOW_SECONDS = 600      # fenêtre glissante 10 min


def _generate_otp(length: int = 6) -> str:
    return "".join(random.choices(string.digits, k=length))


async def _check_rate(redis: Redis, key: str, max_count: int, window: int) -> None:
    """Lève HTTP 429 si le compteur dépasse la limite."""
    count = await redis.incr(key)
    if count == 1:
        await redis.expire(key, window)
    if count > max_count:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail=f"Trop de tentatives. Réessayez dans quelques minutes.",
        )


async def create_otp(redis: Redis, phone_number: str) -> str:
    await _check_rate(redis, f"{_RATE_REQ_PREFIX}{phone_number}", _MAX_REQUESTS_PER_WINDOW, _RATE_WINDOW_SECONDS)
    code = _generate_otp()
    key = f"{OTP_KEY_PREFIX}{phone_number}"
    await redis.set(key, code, ex=OTP_TTL_SECONDS)
    return code


async def verify_otp(redis: Redis, phone_number: str, code: str) -> bool:
    await _check_rate(redis, f"{_RATE_VER_PREFIX}{phone_number}", _MAX_VERIFY_ATTEMPTS, _RATE_WINDOW_SECONDS)
    key = f"{OTP_KEY_PREFIX}{phone_number}"
    stored = await redis.get(key)
    if stored is None:
        return False
    if stored.decode() != code:
        return False
    await redis.delete(key)
    # Vérification réussie → reset le compteur de tentatives
    await redis.delete(f"{_RATE_VER_PREFIX}{phone_number}")
    return True
