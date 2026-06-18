"""make phone_number nullable for Google auth users

Revision ID: 005
Revises: 004
Create Date: 2026-06-18
"""
from alembic import op
import sqlalchemy as sa

revision = '005'
down_revision = '004'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.alter_column(
        'users',
        'phone_number',
        existing_type=sa.String(100),
        nullable=True,
        schema='docretour',
    )


def downgrade() -> None:
    # Remplit les NULL avec un placeholder avant de remettre NOT NULL
    op.execute(
        "UPDATE docretour.users SET phone_number = 'unknown_' || id::text WHERE phone_number IS NULL"
    )
    op.alter_column(
        'users',
        'phone_number',
        existing_type=sa.String(100),
        nullable=False,
        schema='docretour',
    )
