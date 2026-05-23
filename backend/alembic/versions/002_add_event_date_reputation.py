"""002 — add event_date to declarations, score_reputation to users, confirmation fields to matches

Revision ID: 002
Revises: 001
Create Date: 2026-05-24
"""
from alembic import op
import sqlalchemy as sa

revision = "002"
down_revision = "001"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # declarations.event_date
    op.add_column(
        "declarations",
        sa.Column("event_date", sa.Date, nullable=True),
        schema="docretour",
    )
    op.create_index(
        "ix_declarations_event_date",
        "declarations",
        ["event_date"],
        schema="docretour",
    )

    # users.score_reputation
    op.add_column(
        "users",
        sa.Column(
            "score_reputation",
            sa.Float,
            nullable=False,
            server_default="5.0",
        ),
        schema="docretour",
    )

    # matches: double-confirmation columns
    op.add_column(
        "matches",
        sa.Column("confirmed_by_owner", sa.Boolean, nullable=False, server_default="false"),
        schema="docretour",
    )
    op.add_column(
        "matches",
        sa.Column("confirmed_by_finder", sa.Boolean, nullable=False, server_default="false"),
        schema="docretour",
    )


def downgrade() -> None:
    op.drop_column("matches", "confirmed_by_finder", schema="docretour")
    op.drop_column("matches", "confirmed_by_owner", schema="docretour")
    op.drop_column("users", "score_reputation", schema="docretour")
    op.drop_index("ix_declarations_event_date", table_name="declarations", schema="docretour")
    op.drop_column("declarations", "event_date", schema="docretour")
