"""
Tests for declaration_service: CRUD, F-15 active limit, cursor pagination.
"""
import uuid
from datetime import date

import pytest_asyncio
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.declaration import Declaration
from app.schemas.declaration import DeclarationCreate
from app.services import declaration_service
from tests.conftest import make_user


async def _make_declaration(db: AsyncSession, user_id: uuid.UUID, status: str = "active") -> Declaration:
    decl = Declaration(
        id=uuid.uuid4(), user_id=user_id,
        declaration_type="lost", document_type="cni",
        photo_urls=[], status=status,
    )
    db.add(decl)
    await db.flush()
    return decl


async def test_count_active_zero(db: AsyncSession):
    user = await make_user(db)
    assert await declaration_service.count_active(db, user.id) == 0


async def test_count_active_counts_only_active(db: AsyncSession):
    user = await make_user(db)
    await _make_declaration(db, user.id, status="active")
    await _make_declaration(db, user.id, status="active")
    await _make_declaration(db, user.id, status="closed")
    assert await declaration_service.count_active(db, user.id) == 2


async def test_f15_limit_three_active(db: AsyncSession):
    user = await make_user(db)
    for _ in range(3):
        await _make_declaration(db, user.id)
    assert await declaration_service.count_active(db, user.id) == 3


async def test_cursor_pagination_first_page(db: AsyncSession):
    user = await make_user(db)
    for _ in range(5):
        await _make_declaration(db, user.id)
    page = await declaration_service.list_declarations_cursor(db, user.id, limit=3)
    assert len(page) == 3


async def test_cursor_pagination_second_page(db: AsyncSession):
    user = await make_user(db)
    for _ in range(5):
        await _make_declaration(db, user.id)
    page1 = await declaration_service.list_declarations_cursor(db, user.id, limit=3)
    cursor = page1[-1].created_at.isoformat()
    page2 = await declaration_service.list_declarations_cursor(db, user.id, limit=3, cursor=cursor)
    assert len(page2) == 2
    assert {d.id for d in page1}.isdisjoint({d.id for d in page2})


async def test_create_and_get_declaration(db: AsyncSession):
    user = await make_user(db)
    data = DeclarationCreate(
        declaration_type="lost", document_type="passport",
        document_number="A1234567", owner_name="Jean Paul",
        event_date=date.today(),
    )
    decl = await declaration_service.create_declaration(db, user, data, photos=[])
    fetched = await declaration_service.get_declaration(db, decl.id, user.id)
    assert fetched is not None
    assert fetched.document_number == "A1234567"
    assert fetched.event_date == date.today()


async def test_delete_declaration(db: AsyncSession):
    user = await make_user(db)
    decl = await _make_declaration(db, user.id)
    await declaration_service.delete_declaration(db, decl)
    assert await declaration_service.get_declaration(db, decl.id, user.id) is None
