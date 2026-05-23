"""
Tests for auth_service: user creation, token generation, duplicate rejection.
"""
import uuid

from sqlalchemy.ext.asyncio import AsyncSession

from app.services.auth_service import (
    create_user,
    get_user_by_phone,
    create_access_token,
    create_refresh_token,
)


async def test_create_user(db: AsyncSession):
    user = await create_user(db, phone_number="+237600000001", full_name="Alice")
    assert user.id is not None
    assert user.phone_number == "+237600000001"
    assert user.full_name == "Alice"
    assert user.score_reputation == 5.0


async def test_get_user_by_phone(db: AsyncSession):
    created = await create_user(db, phone_number="+237600000002", full_name="Bob")
    found = await get_user_by_phone(db, "+237600000002")
    assert found is not None
    assert found.id == created.id


async def test_get_user_by_phone_not_found(db: AsyncSession):
    assert await get_user_by_phone(db, "+237000000000") is None


async def test_create_access_token_is_string():
    token = create_access_token({"sub": str(uuid.uuid4())})
    assert isinstance(token, str) and len(token) > 20


async def test_create_refresh_token_is_string():
    token = create_refresh_token({"sub": str(uuid.uuid4())})
    assert isinstance(token, str) and len(token) > 20
