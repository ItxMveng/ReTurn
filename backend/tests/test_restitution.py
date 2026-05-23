"""
Tests for restitution_service: create, authorize, double-confirm flow, rating.
"""
import uuid

import pytest_asyncio
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.declaration import Declaration
from app.models.match import Match
from app.schemas.restitution import RestitutionUpdate
from app.services import restitution_service
from tests.conftest import make_user


@pytest_asyncio.fixture
async def confirmed_match(db: AsyncSession):
    owner = await make_user(db, name="Owner")
    finder = await make_user(db, name="Finder")
    lost = Declaration(
        id=uuid.uuid4(), user_id=owner.id, declaration_type="lost",
        document_type="cni", photo_urls=[],
    )
    found = Declaration(
        id=uuid.uuid4(), user_id=finder.id, declaration_type="found",
        document_type="cni", photo_urls=[],
    )
    db.add_all([lost, found])
    await db.flush()
    match = Match(
        id=uuid.uuid4(),
        declaration_found_id=found.id,
        declaration_lost_id=lost.id,
        user_found_id=finder.id,
        user_lost_id=owner.id,
        score=0.95,
        status="confirmed",
        confirmed_by_owner=True,
        confirmed_by_finder=True,
    )
    db.add(match)
    await db.flush()
    return match, owner, finder


async def test_create_restitution(db: AsyncSession, confirmed_match):
    match, _, _ = confirmed_match
    restitution = await restitution_service.create_restitution(db, match.id)
    assert restitution.id is not None
    assert restitution.match_id == match.id
    assert restitution.status == "pending"


async def test_create_restitution_idempotent(db: AsyncSession, confirmed_match):
    match, _, _ = confirmed_match
    r1 = await restitution_service.create_restitution(db, match.id)
    r2 = await restitution_service.create_restitution(db, match.id)
    assert r1.id == r2.id


async def test_get_restitution_authorized(db: AsyncSession, confirmed_match):
    match, owner, finder = confirmed_match
    restitution = await restitution_service.create_restitution(db, match.id)
    assert await restitution_service.get_restitution(db, restitution.id, owner.id) is not None
    assert await restitution_service.get_restitution(db, restitution.id, finder.id) is not None


async def test_get_restitution_unauthorized(db: AsyncSession, confirmed_match):
    match, _, _ = confirmed_match
    restitution = await restitution_service.create_restitution(db, match.id)
    stranger = await make_user(db, name="Stranger")
    assert await restitution_service.get_restitution(db, restitution.id, stranger.id) is None


async def test_update_restitution_location(db: AsyncSession, confirmed_match):
    match, _, _ = confirmed_match
    restitution = await restitution_service.create_restitution(db, match.id)
    updated = await restitution_service.update_restitution(
        db, restitution, RestitutionUpdate(meeting_location="Place de la République, Douala")
    )
    assert updated.meeting_location == "Place de la République, Douala"


async def test_complete_and_rate(db: AsyncSession, confirmed_match):
    match, owner, finder = confirmed_match
    restitution = await restitution_service.create_restitution(db, match.id)
    await restitution_service.update_restitution(db, restitution, RestitutionUpdate(status="completed"))
    initial_rep = finder.score_reputation
    await restitution_service.submit_rating(db, restitution, owner.id, 5)
    await db.refresh(finder)
    assert finder.score_reputation > initial_rep


async def test_double_rating_ignored(db: AsyncSession, confirmed_match):
    match, owner, finder = confirmed_match
    restitution = await restitution_service.create_restitution(db, match.id)
    await restitution_service.update_restitution(db, restitution, RestitutionUpdate(status="completed"))
    await restitution_service.submit_rating(db, restitution, owner.id, 5)
    rep_after_first = finder.score_reputation
    await restitution_service.submit_rating(db, restitution, owner.id, 1)  # second rating ignored
    await db.refresh(finder)
    assert finder.score_reputation == rep_after_first
