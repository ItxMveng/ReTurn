"""
Tests — Module Admin (F-40 à F-44 + CDC §11.1 audit logs)

Couverture :
  - GET  /admin/stats             → KPIs globaux
  - GET  /admin/stats/chart       → séries temporelles
  - PATCH /admin/users/{id}/ban   → bannissement + audit log créé
  - PATCH /admin/users/{id}/unban → rétablissement
  - PATCH /admin/users/{id}/promote → promotion admin
  - PATCH /admin/declarations/{id}/flag → signalement + audit log
  - DELETE /admin/declarations/{id}     → suppression modération
  - POST  /admin/zones            → création zone certifiée
  - PATCH /admin/zones/{id}       → mise à jour zone
  - DELETE /admin/zones/{id}      → suppression zone
  - GET  /admin/audit-logs        → historique filtré
  - POST /admin/declarations/bulk → import CSV en lot
  - Accès non-admin → 403
"""
import csv
import io
import uuid

import pytest
import pytest_asyncio
from httpx import AsyncClient, ASGITransport
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.main import app
from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.audit_log import AuditLog
from app.models.declaration import Declaration
from app.models.user import User
from app.models.zone import Zone
from tests.conftest import make_user


# ─── helpers ──────────────────────────────────────────────────────────────────

def _make_client(db: AsyncSession, user: User) -> AsyncClient:
    """Client httpx avec la DB et l'utilisateur injectés."""
    app.dependency_overrides[get_db] = lambda: db
    app.dependency_overrides[get_current_user] = lambda: user
    return AsyncClient(transport=ASGITransport(app=app), base_url="http://test")


async def _make_admin(db: AsyncSession, phone: str = None) -> User:
    user = await make_user(db, phone=phone)
    user.is_admin = True
    await db.flush()
    return user


async def _make_declaration(db: AsyncSession, user: User) -> Declaration:
    decl = Declaration(
        id=uuid.uuid4(),
        user_id=user.id,
        declaration_type="found",
        document_type="cni",
        status="active",
        is_flagged=False,
    )
    db.add(decl)
    await db.flush()
    return decl


async def _make_zone(db: AsyncSession) -> Zone:
    zone = Zone(
        id=uuid.uuid4(),
        name="Commissariat de Bonanjo",
        zone_type="commissariat",
        address="Rue de la Paix, Douala",
        latitude=4.0511,
        longitude=9.7085,
        is_certified=True,
    )
    db.add(zone)
    await db.flush()
    return zone


# ─── stats ────────────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_global_stats_returns_structure(db: AsyncSession):
    admin = await _make_admin(db)
    async with _make_client(db, admin) as client:
        resp = await client.get("/api/v1/admin/stats")
    assert resp.status_code == 200
    data = resp.json()
    assert "total_users" in data
    assert "restitution_success_rate" in data
    assert data["period_days"] == 30


@pytest.mark.asyncio
async def test_global_stats_custom_period(db: AsyncSession):
    admin = await _make_admin(db)
    async with _make_client(db, admin) as client:
        resp = await client.get("/api/v1/admin/stats?period_days=7")
    assert resp.status_code == 200
    assert resp.json()["period_days"] == 7


@pytest.mark.asyncio
async def test_stats_chart_returns_list(db: AsyncSession):
    admin = await _make_admin(db)
    async with _make_client(db, admin) as client:
        resp = await client.get("/api/v1/admin/stats/chart?period_days=7")
    assert resp.status_code == 200
    data = resp.json()
    assert isinstance(data, list)
    assert len(data) == 7
    assert "date" in data[0]
    assert "declarations" in data[0]


# ─── accès non-admin ──────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_non_admin_is_rejected(db: AsyncSession):
    regular_user = await make_user(db)
    async with _make_client(db, regular_user) as client:
        resp = await client.get("/api/v1/admin/stats")
    assert resp.status_code == 403


# ─── ban / unban / promote ────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_ban_user_creates_audit_log(db: AsyncSession):
    admin = await _make_admin(db)
    target = await make_user(db)

    async with _make_client(db, admin) as client:
        resp = await client.patch(
            f"/api/v1/admin/users/{target.id}/ban",
            json={"reason": "Comportement suspect"},
        )
    assert resp.status_code == 200

    # Vérifier que le user est bien banni
    await db.refresh(target)
    assert target.is_banned is True

    # Vérifier l'audit log
    logs = (await db.execute(
        select(AuditLog).where(
            AuditLog.action_type == "user.ban",
            AuditLog.target_id == str(target.id),
        )
    )).scalars().all()
    assert len(logs) == 1
    assert logs[0].extra["reason"] == "Comportement suspect"


@pytest.mark.asyncio
async def test_ban_self_is_rejected(db: AsyncSession):
    admin = await _make_admin(db)
    async with _make_client(db, admin) as client:
        resp = await client.patch(
            f"/api/v1/admin/users/{admin.id}/ban",
            json={"reason": "Test"},
        )
    assert resp.status_code == 400


@pytest.mark.asyncio
async def test_unban_user(db: AsyncSession):
    admin = await _make_admin(db)
    target = await make_user(db)
    target.is_banned = True
    await db.flush()

    async with _make_client(db, admin) as client:
        resp = await client.patch(f"/api/v1/admin/users/{target.id}/unban")
    assert resp.status_code == 200
    await db.refresh(target)
    assert target.is_banned is False


@pytest.mark.asyncio
async def test_promote_user_to_admin(db: AsyncSession):
    admin = await _make_admin(db)
    target = await make_user(db)
    assert target.is_admin is False or target.is_admin is None

    async with _make_client(db, admin) as client:
        resp = await client.patch(f"/api/v1/admin/users/{target.id}/promote")
    assert resp.status_code == 200
    await db.refresh(target)
    assert target.is_admin is True


# ─── modération déclarations ──────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_flag_declaration_creates_audit_log(db: AsyncSession):
    admin = await _make_admin(db)
    user = await make_user(db)
    decl = await _make_declaration(db, user)

    async with _make_client(db, admin) as client:
        resp = await client.patch(f"/api/v1/admin/declarations/{decl.id}/flag")
    assert resp.status_code == 200

    await db.refresh(decl)
    assert decl.is_flagged is True

    logs = (await db.execute(
        select(AuditLog).where(
            AuditLog.action_type == "declaration.flag",
            AuditLog.target_id == str(decl.id),
        )
    )).scalars().all()
    assert len(logs) == 1


@pytest.mark.asyncio
async def test_delete_declaration(db: AsyncSession):
    admin = await _make_admin(db)
    user = await make_user(db)
    decl = await _make_declaration(db, user)
    decl_id = decl.id

    async with _make_client(db, admin) as client:
        resp = await client.delete(f"/api/v1/admin/declarations/{decl_id}")
    assert resp.status_code == 204

    gone = await db.get(Declaration, decl_id)
    assert gone is None


# ─── zones ────────────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_create_zone(db: AsyncSession):
    admin = await _make_admin(db)
    payload = {
        "name": "Mairie de Yaoundé I",
        "zone_type": "mairie",
        "latitude": 3.8667,
        "longitude": 11.5167,
        "address": "Centre Ville, Yaoundé",
        "is_certified": True,
    }
    async with _make_client(db, admin) as client:
        resp = await client.post("/api/v1/admin/zones", json=payload)
    assert resp.status_code == 201
    data = resp.json()
    assert data["name"] == "Mairie de Yaoundé I"
    assert data["is_certified"] is True


@pytest.mark.asyncio
async def test_update_zone(db: AsyncSession):
    admin = await _make_admin(db)
    zone = await _make_zone(db)

    async with _make_client(db, admin) as client:
        resp = await client.patch(
            f"/api/v1/admin/zones/{zone.id}",
            json={"name": "Commissariat Central Bonanjo"},
        )
    assert resp.status_code == 200
    assert resp.json()["name"] == "Commissariat Central Bonanjo"


@pytest.mark.asyncio
async def test_delete_zone(db: AsyncSession):
    admin = await _make_admin(db)
    zone = await _make_zone(db)
    zone_id = zone.id

    async with _make_client(db, admin) as client:
        resp = await client.delete(f"/api/v1/admin/zones/{zone_id}")
    assert resp.status_code == 204

    gone = await db.get(Zone, zone_id)
    assert gone is None


# ─── audit logs ───────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_audit_logs_list(db: AsyncSession):
    admin = await _make_admin(db)
    target = await make_user(db)

    # Générer au moins un log via ban
    async with _make_client(db, admin) as client:
        await client.patch(
            f"/api/v1/admin/users/{target.id}/ban",
            json={"reason": "Test audit"},
        )
        resp = await client.get("/api/v1/admin/audit-logs")
    assert resp.status_code == 200
    logs = resp.json()
    assert isinstance(logs, list)
    assert any(log["action_type"] == "user.ban" for log in logs)


@pytest.mark.asyncio
async def test_audit_logs_filter_by_action_type(db: AsyncSession):
    admin = await _make_admin(db)
    async with _make_client(db, admin) as client:
        resp = await client.get("/api/v1/admin/audit-logs?action_type=user.ban")
    assert resp.status_code == 200
    for log in resp.json():
        assert log["action_type"] == "user.ban"


# ─── import CSV bulk ─────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_bulk_import_declarations(db: AsyncSession):
    admin = await _make_admin(db)
    csv_content = (
        "document_type,owner_name,location_description\n"
        "cni,Jean Dupont,Marché Central Douala\n"
        "permis,Marie Martin,Gare Routière Yaoundé\n"
    )
    csv_bytes = csv_content.encode("utf-8")

    async with _make_client(db, admin) as client:
        resp = await client.post(
            "/api/v1/admin/declarations/bulk",
            files={
                "file": ("import.csv", io.BytesIO(csv_bytes), "text/csv")
            },
        )
    assert resp.status_code == 201
    data = resp.json()
    assert data["rows_created"] == 2
    assert data["errors"] == []
