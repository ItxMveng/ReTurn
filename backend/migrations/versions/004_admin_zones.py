"""
004 — Colonnes admin (is_admin, is_banned) sur users + table zones_recuperation

Revision ID: 004
Down revision: 003
"""
from alembic import op
import sqlalchemy as sa

revision = "004"
down_revision = "003"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Colonnes admin sur users
    op.add_column("users", sa.Column("is_admin", sa.Boolean(), nullable=False, server_default="false"))
    op.add_column("users", sa.Column("is_banned", sa.Boolean(), nullable=False, server_default="false"))

    # Colonne is_flagged sur declarations
    op.add_column("declarations", sa.Column("is_flagged", sa.Boolean(), nullable=False, server_default="false"))

    # Table zones_recuperation
    op.create_table(
        "zones_recuperation",
        sa.Column("id", sa.UUID(), nullable=False),
        sa.Column("name", sa.String(255), nullable=False),
        sa.Column("zone_type", sa.String(50), nullable=False),
        sa.Column("address", sa.String(500), nullable=False),
        sa.Column("latitude", sa.Float(), nullable=False),
        sa.Column("longitude", sa.Float(), nullable=False),
        sa.Column("is_certified", sa.Boolean(), nullable=False, server_default="true"),
        sa.Column("institution_id", sa.UUID(), sa.ForeignKey("users.id", ondelete="SET NULL"), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_zones_zone_type", "zones_recuperation", ["zone_type"])


def downgrade() -> None:
    op.drop_index("ix_zones_zone_type", "zones_recuperation")
    op.drop_table("zones_recuperation")
    op.drop_column("declarations", "is_flagged")
    op.drop_column("users", "is_banned")
    op.drop_column("users", "is_admin")
