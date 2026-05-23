import random
import string

from redis.asyncio import Redis

OTP_TTL_SECONDS = 300  # 5 minutes
OTP_KEY_PREFIX = "otp:"


def _generate_otp(length: int = 6) -> str:
    return "".join(random.choices(string.digits, k=length))


async def create_otp(redis: Redis, phone_number: str) -> str:
    code = _generate_otp()
    key = f"{OTP_KEY_PREFIX}{phone_number}"
    await redis.set(key, code, ex=OTP_TTL_SECONDS)
    return code


async def verify_otp(redis: Redis, phone_number: str, code: str) -> bool:
    key = f"{OTP_KEY_PREFIX}{phone_number}"
    stored = await redis.get(key)
    if stored is None:
        return False
    if stored.decode() != code:
        return False
    await redis.delete(key)
    return True
