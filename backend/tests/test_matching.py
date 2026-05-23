"""
Tests for the matching service — score normalization, fuzzy name matching, haversine.
"""
import uuid
from datetime import date, timedelta

import pytest
import pytest_asyncio
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.declaration import Declaration
from app.services.matching_service import (
    _doc_number_score,
    _name_score,
    _geo_score,
    _date_score,
    compute_score,
)
from tests.conftest import make_user


class TestScoreComponents:
    def test_perfect_doc_number(self):
        assert _doc_number_score("CM12345", "CM12345") == 1.0

    def test_none_doc_number(self):
        assert _doc_number_score(None, None) == 0.0

    def test_partial_doc_number(self):
        score = _doc_number_score("CM12345", "CM12XXX")
        assert 0.0 < score < 1.0

    def test_perfect_name(self):
        assert _name_score("Jean Dupont", "Jean Dupont") == 1.0

    def test_case_insensitive_name(self):
        assert _name_score("jean dupont", "JEAN DUPONT") == 1.0

    def test_similar_name(self):
        score = _name_score("Jean Dupont", "Jean Dupon")
        assert score > 0.8

    def test_none_name(self):
        assert _name_score(None, None) == 0.0

    def test_same_location(self):
        assert _geo_score(4.05, 9.72, 4.05, 9.72) == 1.0

    def test_far_location(self):
        # Douala vs Yaoundé ≈ 200km
        score = _geo_score(4.05, 9.72, 3.86, 11.52)
        assert score < 0.5

    def test_none_location(self):
        assert _geo_score(None, None, None, None) == 0.0

    def test_same_date(self):
        d = date.today()
        assert _date_score(d, d) == 1.0

    def test_date_5_days_apart(self):
        d1 = date.today()
        d2 = d1 + timedelta(days=5)
        score = _date_score(d1, d2)
        assert 0.0 < score < 1.0

    def test_none_date(self):
        assert _date_score(None, None) == 0.0


@pytest_asyncio.fixture
async def two_matching_declarations(db: AsyncSession):
    user1 = await make_user(db, name="Alice")
    user2 = await make_user(db, name="Bob")
    found = Declaration(
        id=uuid.uuid4(), user_id=user2.id, declaration_type="found",
        document_type="cni", document_number="CM999888",
        owner_name="Alice Martin", latitude=4.05, longitude=9.72,
        event_date=date.today(), photo_urls=[],
    )
    lost = Declaration(
        id=uuid.uuid4(), user_id=user1.id, declaration_type="lost",
        document_type="cni", document_number="CM999888",
        owner_name="Alice Martin", latitude=4.05, longitude=9.72,
        event_date=date.today(), photo_urls=[],
    )
    db.add_all([found, lost])
    await db.flush()
    return found, lost, user1, user2


async def test_compute_score_perfect_match(two_matching_declarations):
    found, lost, _, _ = two_matching_declarations
    score = compute_score(found, lost)
    assert score >= 0.9


async def test_compute_score_different_doc_type(db: AsyncSession):
    u1 = await make_user(db)
    u2 = await make_user(db)
    found = Declaration(
        id=uuid.uuid4(), user_id=u1.id, declaration_type="found",
        document_type="passport", photo_urls=[],
    )
    lost = Declaration(
        id=uuid.uuid4(), user_id=u2.id, declaration_type="lost",
        document_type="cni", photo_urls=[],
    )
    db.add_all([found, lost])
    await db.flush()
    score = compute_score(found, lost)
    assert score == 0.0
