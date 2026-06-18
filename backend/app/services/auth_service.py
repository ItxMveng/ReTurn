from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User
from app.schemas.auth import TokenResponse
from app.core.security import create_access_token, create_refresh_token


async def get_or_create_user(
    db: AsyncSession,
    identifier: str,
    firebase_uid: str = "",
    email: str | None = None,
    is_email_auth: bool = False,
) -> tuple[User, bool]:
    """
    Trouve ou crée un utilisateur.

    - OTP (is_email_auth=False) : identifier = phone_number
    - Google (is_email_auth=True) : identifier = email, phone_number non fourni
    """
    # 1. Lookup par firebase_uid (le plus fiable pour les retours)
    if firebase_uid:
        result = await db.execute(select(User).where(User.firebase_uid == firebase_uid))
        user = result.scalar_one_or_none()
        if user:
            if firebase_uid and not user.firebase_uid:
                user.firebase_uid = firebase_uid
            return user, False

    # 2. Lookup par email si authentification Google
    if is_email_auth and email:
        result = await db.execute(select(User).where(User.email == email))
        user = result.scalar_one_or_none()
        if user:
            if firebase_uid and not user.firebase_uid:
                user.firebase_uid = firebase_uid
            return user, False

    # 3. Lookup par numéro de téléphone si authentification OTP
    if not is_email_auth:
        result = await db.execute(select(User).where(User.phone_number == identifier))
        user = result.scalar_one_or_none()
        if user:
            if firebase_uid and not user.firebase_uid:
                user.firebase_uid = firebase_uid
            return user, False

    # 4. Création d'un nouvel utilisateur
    if is_email_auth:
        user = User(
            phone_number=None,
            email=email,
            firebase_uid=firebase_uid or None,
            is_verified=True,
        )
    else:
        user = User(
            phone_number=identifier,
            email=email,
            firebase_uid=firebase_uid or None,
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
