"""Support multi-pays : country_code (ISO 3166-1 alpha-2)

L'application n'était utilisable qu'au Cameroun. Chaque utilisateur,
déclaration et zone de récupération porte désormais un pays ; le matching ne
rapproche que des déclarations du même pays.

Les données existantes (Cameroun uniquement avant cette migration) sont
rattachées à « CM ».

Idempotente : ADD COLUMN IF NOT EXISTS / CREATE INDEX IF NOT EXISTS.

Revision ID: 009
Revises: 008
Create Date: 2026-09-23
"""
from alembic import op

revision = '009'
down_revision = '008'
branch_labels = None
depends_on = None

_TABLES = ("users", "declarations", "zones_recuperation")


def upgrade() -> None:
    for table in _TABLES:
        op.execute(
            f"ALTER TABLE docretour.{table} "
            "ADD COLUMN IF NOT EXISTS country_code VARCHAR(2)"
        )
        op.execute(
            f"UPDATE docretour.{table} SET country_code = 'CM' "
            "WHERE country_code IS NULL"
        )
    for table in ("declarations", "zones_recuperation"):
        op.execute(
            f"CREATE INDEX IF NOT EXISTS ix_{table}_country_code "
            f"ON docretour.{table} (country_code)"
        )


def downgrade() -> None:
    for table in ("declarations", "zones_recuperation"):
        op.execute(f"DROP INDEX IF EXISTS docretour.ix_{table}_country_code")
    for table in _TABLES:
        op.execute(f"ALTER TABLE docretour.{table} DROP COLUMN IF EXISTS country_code")
