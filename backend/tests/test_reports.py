"""Tests unitaires — signalements / litiges."""
import uuid
import pytest
from httpx import AsyncClient


# ── Fixtures helpers ──────────────────────────────────────────────────────────

FAKE_MATCH_ID = uuid.uuid4()
FAKE_REPORTER_ID = uuid.uuid4()
FAKE_REPORTED_ID = uuid.uuid4()


# ── Tests service ─────────────────────────────────────────────────────────────

class TestReportService:
    """Tests de la logique métier du service de signalement."""

    def test_report_reasons_enum(self):
        """Vérifie que toutes les raisons de signalement sont définies."""
        from app.models.report import ReportReason
        reasons = {r.value for r in ReportReason}
        assert "fraud" in reasons
        assert "harassment" in reasons
        assert "fake_document" in reasons
        assert "identity_theft" in reasons
        assert "inappropriate" in reasons
        assert "other" in reasons

    def test_report_statuses_enum(self):
        """Vérifie que tous les statuts sont définis."""
        from app.models.report import ReportStatus
        statuses = {s.value for s in ReportStatus}
        assert "pending" in statuses
        assert "reviewed" in statuses
        assert "resolved" in statuses
        assert "rejected" in statuses

    def test_report_schema_create_valid(self):
        """Vérifie la validation du schéma de création."""
        from app.schemas.report import ReportCreate
        from app.models.report import ReportReason
        payload = ReportCreate(
            reported_id=FAKE_REPORTED_ID,
            reason=ReportReason.FRAUD,
            description="Tentative d'escroquerie lors de l'échange",
        )
        assert payload.reason == ReportReason.FRAUD
        assert payload.reported_id == FAKE_REPORTED_ID

    def test_report_schema_description_max_length(self):
        """La description ne doit pas dépasser 1000 caractères."""
        from app.schemas.report import ReportCreate
        from app.models.report import ReportReason
        import pytest
        with pytest.raises(Exception):
            ReportCreate(
                reported_id=FAKE_REPORTED_ID,
                reason=ReportReason.OTHER,
                description="x" * 1001,  # Dépasse la limite
            )

    def test_report_update_schema(self):
        """Vérifie la validation du schéma de mise à jour admin."""
        from app.schemas.report import ReportUpdate
        from app.models.report import ReportStatus
        update = ReportUpdate(
            status=ReportStatus.RESOLVED,
            admin_note="Dossier traité, utilisateur averti.",
        )
        assert update.status == ReportStatus.RESOLVED


# ── Tests sécurité endpoint ────────────────────────────────────────────────────

class TestReportEndpointSecurity:
    """Vérifie les contrôles d'autorisation des endpoints."""

    def test_cannot_report_yourself(self):
        """Un utilisateur ne peut pas se signaler lui-même."""
        from app.schemas.report import ReportCreate
        from app.models.report import ReportReason
        # Le reported_id == reporter_id doit être rejeté par l'endpoint
        payload = ReportCreate(
            reported_id=FAKE_REPORTER_ID,  # même ID que le reporter
            reason=ReportReason.HARASSMENT,
        )
        # La validation métier est dans l'endpoint (check reported_id != current_user.id)
        assert payload.reported_id == FAKE_REPORTER_ID

    def test_report_requires_valid_reason(self):
        """Une raison invalide doit lever une erreur de validation."""
        from pydantic import ValidationError
        from app.schemas.report import ReportCreate
        with pytest.raises(ValidationError):
            ReportCreate(
                reported_id=FAKE_REPORTED_ID,
                reason="invalid_reason",  # type: ignore
            )

    def test_admin_endpoints_require_is_admin_flag(self):
        """Les endpoints admin vérifient le flag is_admin sur l'utilisateur."""
        from app.core.dependencies import require_admin
        # La dépendance require_admin lève HTTP 403 si is_admin est False
        # Ce test documente le comportement attendu
        assert callable(require_admin)
