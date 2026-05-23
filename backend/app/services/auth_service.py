from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User
from app.schemas.auth import TokenResponse
from app.core.security import create_access_token, create_refresh_token


async def get_or_create_user(
    db: AsyncSession,
    phone_number: str,
    firebase_uid: str = "",
    email: str | None = None,
) -> tuple[User, bool]:
    # Chercher par firebase_uid d'abord (le plus fiable), puis par phone/email
    if firebase_uid:
        result = await db.execute(select(User).where(User.firebase_uid == firebase_uid))
        user = result.scalar_one_or_none()
        if user:
            return user, False

    result = await db.execute(select(User).where(User.phone_number == phone_number))
    user = result.scalar_one_or_none()
    if user:
        # Mettre à jour le firebase_uid s'il manquait
        if firebase_uid and not user.firebase_uid:
            user.firebase_uid = firebase_uid
        return user, False

    user = User(
        phone_number=phone_number,
        firebase_uid=firebase_uid or None,
        email=email,
        is_verified=True,
    )
    db.add(user)
    await db.flush()
    return user, True


async def issue_tokens(user: User) -> TokenResponse:
    subject = str(user.id)
    return TokenResponse(
        access_token=create_access_token(subject),
        refresh_token=create_refresh_token(subject),
        user_id=subject,
    )
