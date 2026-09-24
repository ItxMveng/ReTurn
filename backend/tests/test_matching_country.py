"""Le matching ne rapproche que des déclarations d'un même pays."""
import uuid
from datetime import date
from unittest.mock import AsyncMock

import pytest

from app.models.declaration import Declaration
from app.services.matching_service import run_matching
from tests.conftest import make_user


def _declaration(user, kind: str, country: str | None) -> Declaration:
    return Declaration(
        id=uuid.uuid4(),
        user_id=user.id,
        declaration_type=kind,
        document_type="cni",
        document_number="AB123456",
        owner_name="Jean Dupont",
        country_code=country,
        status="active",
        photo_urls=[],
        event_date=date(2026, 9, 1),
    )


async def _run(db, found_country: str | None, lost_country: str | None):
    finder = await make_user(db)
    owner = await make_user(db)
    found = _declaration(finder, "found", found_country)
    db.add(found)
    await db.flush()
    lost = _declaration(owner, "lost", lost_country)
    db.add(lost)
    await db.flush()
    return await run_matching(db, AsyncMock(), lost)


@pytest.mark.asyncio
async def test_same_country_matches(db):
    assert len(await _run(db, "FR", "FR")) == 1


@pytest.mark.asyncio
async def test_different_countries_do_not_match(db):
    assert await _run(db, "CM", "FR") == []


@pytest.mark.asyncio
async def test_unknown_country_stays_matchable(db):
    # Anciennes données sans pays : on reste tolérant plutôt que de perdre des matchs.
    assert len(await _run(db, None, "FR")) == 1
