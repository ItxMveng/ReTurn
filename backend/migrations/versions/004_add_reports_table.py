"""add reports table

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
    # Enum types
    report_reason = postgresql.ENUM(
        "fraud", "harassment", "fake_document",
        "identity_theft", "inappropriate", "other",
        name="reportreason",
    )
    report_status = postgresql.ENUM(
        "pending", "reviewed", "resolved", "rejected",
        name="reportstatus",
    )
    report_reason.create(op.get_bind(), checkfirst=True)
    report_status.create(op.get_bind(), checkfirst=True)

    op.create_table(
        "reports",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "match_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("matches.id", ondelete="CASCADE"),
            nullable=False,
            index=True,
        ),
        sa.Column(
            "reporter_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
            index=True,
        ),
        sa.Column(
            "reported_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
            index=True,
        ),
        sa.Column("reason", sa.Enum(name="reportreason"), nullable=False),
        sa.Column("description", sa.Text, nullable=True),
        sa.Column("screenshot_url", sa.String(500), nullable=True),
        sa.Column(
            "status",
            sa.Enum(name="reportstatus"),
            nullable=False,
            server_default="pending",
            index=True,
        ),
        sa.Column("admin_note", sa.Text, nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.Column("resolved_at", sa.DateTime(timezone=True), nullable=True),
    )


def downgrade() -> None:
    op.drop_table("reports")
    op.execute("DROP TYPE IF EXISTS reportstatus")
    op.execute("DROP TYPE IF EXISTS reportreason")
