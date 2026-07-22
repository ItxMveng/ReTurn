"""
Promote a user to admin by phone number.

Usage (inside the backend container):
    docker compose -f infra/docker-compose.yml exec backend python promote_admin.py +237XXXXXXXXX

Or from host after: docker compose exec backend python promote_admin.py +237XXXXXXXXX
"""
import asyncio
import sys

from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker

from app.core.config import settings
from app.models.user import User


async def promote(phone: str) -> None:
    engine = create_async_engine(settings.DATABASE_URL, echo=False)
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async with async_session() as session:
        result = await session.execute(
            select(User).where(User.phone_number == phone)
        )
        user = result.scalar_one_or_none()

        if user is None:
            print(f"[ERREUR] Aucun utilisateur trouvé avec le numéro : {phone}")
            print("  → Connectez-vous d'abord via l'app OTP pour créer le compte.")
            await engine.dispose()
            sys.exit(1)

        if user.is_admin:
            print(f"[INFO] {phone} est déjà administrateur.")
            await engine.dispose()
            return

        user.is_admin = True
        await session.commit()
        print(f"[OK] {phone} (id={user.id}) est maintenant administrateur.")

    await engine.dispose()


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python promote_admin.py +237XXXXXXXXX")
        sys.exit(1)
    asyncio.run(promote(sys.argv[1]))
