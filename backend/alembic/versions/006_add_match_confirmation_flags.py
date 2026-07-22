"""add confirmed_by_owner / confirmed_by_finder to matches

Le modèle Match (app/models/match.py) référence ces deux colonnes, mais la
migration initiale (001) ne les créait pas. Toute requête sur la table matches
échouait alors avec « column matches.confirmed_by_owner does not exist » (500).
Cette migration ajoute les colonnes manquantes.

Idempotente : utilise IF NOT EXISTS pour ne rien casser si les colonnes
existaient déjà (bases créées via Base.metadata.create_all).

Revision ID: 006
Revises: 005
Create Date: 2026-06-23
"""
from alembic import op

revision = '006'
down_revision = '005'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute(
        "ALTER TABLE docretour.matches "
        "ADD COLUMN IF NOT EXISTS confirmed_by_owner BOOLEAN NOT NULL DEFAULT FALSE"
    )
    op.execute(
        "ALTER TABLE docretour.matches "
        "ADD COLUMN IF NOT EXISTS confirmed_by_finder BOOLEAN NOT NULL DEFAULT FALSE"
    )


def downgrade() -> None:
    op.execute("ALTER TABLE docretour.matches DROP COLUMN IF EXISTS confirmed_by_finder")
    op.execute("ALTER TABLE docretour.matches DROP COLUMN IF EXISTS confirmed_by_owner")
