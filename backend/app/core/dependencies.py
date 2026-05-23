import uuid

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.database import get_db
from app.models.user import User

bearer_scheme = HTTPBearer()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
    db: AsyncSession = Depends(get_db),
) -> User:
    token = credentials.credentials

    # 1. Essayer le JWT backend (token normal)
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        user_id: str = payload.get("sub")
        if user_id is None:
            raise ValueError
        result = await db.execute(select(User).where(User.id == uuid.UUID(user_id)))
        user = result.scalar_one_or_none()
        if user and user.is_active:
            return user
    except (JWTError, ValueError):
        pass

    # 2. Fallback : essayer comme Firebase token (cas offline-first)
    try:
        from app.core.firebase_admin import verify_firebase_token
        decoded = verify_firebase_token(token)
        firebase_uid = decoded.get("uid")
        if firebase_uid:
            result = await db.execute(
                select(User).where(User.firebase_uid == firebase_uid)
            )
            user = result.scalar_one_or_none()
            if user and user.is_active:
                return user
    except Exception:
        pass

    raise HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Token invalide ou expiré",
    )
