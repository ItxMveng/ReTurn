"""004 — Ajout tables admin : zones, reports, audit_logs, connection_logs

Revision ID: 004
Revises: 003
Create Date: 2026-05-24
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = "004"
down_revision = "003"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # ── colonnes admin ─────────────────────────────────────────────────────────
    op.add_column(
        "users",
        sa.Column("is_admin", sa.Boolean(), nullable=False, server_default="false"),
        schema="docretour",
    )
    op.add_column(
        "users",
        sa.Column("is_banned", sa.Boolean(), nullable=False, server_default="false"),
        schema="docretour",
    )

    # ── zones ──────────────────────────────────────────────────────────────────
    op.create_table(
        "zones_recuperation",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("name", sa.String(length=255), nullable=False),
        sa.Column("zone_type", sa.String(length=50), nullable=False),
        sa.Column("address", sa.String(length=500), nullable=False),
        sa.Column("latitude", sa.Float(), nullable=False),
        sa.Column("longitude", sa.Float(), nullable=False),
        sa.Column("is_certified", sa.Boolean(), nullable=False, server_default="true"),
        sa.Column(
            "institution_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("docretour.users.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        schema="docretour",
    )
    op.create_index("ix_zones_zone_type", "zones_recuperation", ["zone_type"], schema="docretour")
    op.create_index("ix_zones_is_certified", "zones_recuperation", ["is_certified"], schema="docretour")

    # ── reports ────────────────────────────────────────────────────────────────
    op.create_table(
        "reports",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "match_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("docretour.matches.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "reporter_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("docretour.users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "reported_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("docretour.users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("reason", sa.String(length=50), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("screenshot_url", sa.String(length=500), nullable=True),
        sa.Column("status", sa.String(length=20), nullable=False, server_default="pending"),
        sa.Column("admin_note", sa.Text(), nullable=True),
        sa.Column("resolved_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        schema="docretour",
    )
    op.create_index("ix_reports_match_id", "reports", ["match_id"], schema="docretour")
    op.create_index("ix_reports_status", "reports", ["status"], schema="docretour")
    op.create_index("ix_reports_reported_id", "reports", ["reported_id"], schema="docretour")
    op.create_index("ix_reports_reporter_id", "reports", ["reporter_id"], schema="docretour")

    # ── audit_logs ─────────────────────────────────────────────────────────────
    op.create_table(
        "audit_logs",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "admin_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("docretour.users.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column("action_type", sa.String(length=80), nullable=False),
        sa.Column("target_type", sa.String(length=50), nullable=True),
        sa.Column("target_id", sa.String(length=100), nullable=True),
        sa.Column("ip_address", sa.String(length=45), nullable=True),
        sa.Column("extra", postgresql.JSONB(), nullable=True, server_default="{}"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        schema="docretour",
    )
    op.create_index("ix_audit_logs_admin_id", "audit_logs", ["admin_id"], schema="docretour")
    op.create_index("ix_audit_logs_action_type", "audit_logs", ["action_type"], schema="docretour")
    op.create_index("ix_audit_logs_created_at", "audit_logs", ["created_at"], schema="docretour")

    # ── connection_logs ────────────────────────────────────────────────────────
    op.create_table(
        "connection_logs",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "user_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("docretour.users.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column("phone_number", sa.String(length=20), nullable=True),
        sa.Column("ip_address", sa.String(length=45), nullable=True),
        sa.Column("user_agent", sa.String(length=500), nullable=True),
        sa.Column("device_id", sa.String(length=200), nullable=True),
        sa.Column("auth_method", sa.String(length=20), nullable=False, server_default="otp"),
        sa.Column("status", sa.String(length=20), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        schema="docretour",
    )
    op.create_index("ix_connection_logs_user_id", "connection_logs", ["user_id"], schema="docretour")
    op.create_index("ix_connection_logs_ip_address", "connection_logs", ["ip_address"], schema="docretour")
    op.create_index("ix_connection_logs_status", "connection_logs", ["status"], schema="docretour")
    op.create_index("ix_connection_logs_created_at", "connection_logs", ["created_at"], schema="docretour")

    # ── colonne is_flagged sur declarations (si absente) ───────────────────────
    op.add_column(
        "declarations",
        sa.Column("is_flagged", sa.Boolean(), nullable=False, server_default="false"),
        schema="docretour",
    )


def downgrade() -> None:
    op.drop_column("declarations", "is_flagged", schema="docretour")
    op.drop_table("connection_logs", schema="docretour")
    op.drop_table("audit_logs", schema="docretour")
    op.drop_table("reports", schema="docretour")
    op.drop_table("zones_recuperation", schema="docretour")
    op.drop_column("users", "is_banned", schema="docretour")
    op.drop_column("users", "is_admin", schema="docretour")
