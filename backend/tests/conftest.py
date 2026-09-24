"""
Shared pytest fixtures for DocRetour backend tests.
Uses an in-memory SQLite database (via aiosqlite) so no real Postgres is needed.
"""
import uuid
from unittest.mock import AsyncMock, MagicMock

import pytest
import pytest_asyncio
from sqlalchemy import event
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker

from app.core.database import Base
from app.models import *  # noqa: F401,F403 — register all models with Base.metadata
from app.models.user import User

DATABASE_URL = "sqlite+aiosqlite:///:memory:"


@pytest_asyncio.fixture(scope="session")
async def engine():
    engine = create_async_engine(DATABASE_URL, future=True)

    # Les modèles vivent dans le schéma PostgreSQL « docretour » : on l'émule en
    # attachant une base SQLite mémoire portant ce nom à chaque connexion.
    @event.listens_for(engine.sync_engine, "connect")
    def _attach_docretour_schema(dbapi_connection, _record):
        cursor = dbapi_connection.cursor()
        cursor.execute("ATTACH DATABASE ':memory:' AS docretour")
        cursor.close()

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield engine
    await engine.dispose()


@pytest_asyncio.fixture
async def db(engine):
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    async with async_session() as session:
        yield session
        await session.rollback()


@pytest.fixture
def fake_redis():
    redis = MagicMock()
    redis.publish = AsyncMock(return_value=1)
    redis.lpush = AsyncMock(return_value=1)
    redis.ltrim = AsyncMock(return_value=True)
    redis.lrange = AsyncMock(return_value=[])
    redis.rpush = AsyncMock(return_value=1)
    redis.llen = AsyncMock(return_value=0)
    redis.delete = AsyncMock(return_value=1)
    return redis


@pytest.fixture(autouse=True)
def mock_storage(monkeypatch):
    """Prevent any real MinIO calls in tests."""
    import app.services.storage_service as ss
    monkeypatch.setattr(ss, "ensure_bucket", AsyncMock())
    monkeypatch.setattr(ss, "upload_photo", AsyncMock(return_value="http://minio/test/photo.jpg"))
    monkeypatch.setattr(ss, "delete_photo", AsyncMock())


async def make_user(db: AsyncSession, phone: str = None, name: str = "Test User") -> User:
    user = User(
        id=uuid.uuid4(),
        phone_number=phone or f"+237{uuid.uuid4().hex[:9]}",
        full_name=name,
        score_reputation=5.0,
    )
    db.add(user)
    await db.flush()
    return user
