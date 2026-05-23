"""003 — add restitutions table

Revision ID: 003
Revises: 002
Create Date: 2026-05-24
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID

revision = "003"
down_revision = "002"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "restitutions",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "match_id",
            UUID(as_uuid=True),
            sa.ForeignKey("docretour.matches.id", ondelete="CASCADE"),
            nullable=False,
            unique=True,
        ),
        sa.Column("meeting_location", sa.String(300), nullable=True),
        sa.Column("meeting_latitude", sa.Float, nullable=True),
        sa.Column("meeting_longitude", sa.Float, nullable=True),
        sa.Column("proof_photos", sa.JSON, nullable=False, server_default="[]"),
        sa.Column("status", sa.String(20), nullable=False, server_default="pending"),
        sa.Column("rating_by_owner", sa.Integer, nullable=True),
        sa.Column("rating_by_finder", sa.Integer, nullable=True),
        sa.Column("completed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        schema="docretour",
    )
    op.create_index(
        "ix_restitutions_match_id",
        "restitutions",
        ["match_id"],
        schema="docretour",
    )
    op.create_index(
        "ix_restitutions_status",
        "restitutions",
        ["status"],
        schema="docretour",
    )


def downgrade() -> None:
    op.drop_table("restitutions", schema="docretour")
