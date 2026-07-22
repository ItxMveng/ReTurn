"""Dossiers multi-documents : group_id sur les déclarations

Plusieurs documents trouvés/perdus en même temps (ex. un portefeuille)
peuvent être déclarés en une seule fois : chaque document devient une
déclaration à part entière (matching individuel), reliées par un group_id
commun. Un dossier compte pour UNE seule déclaration dans la limite F-15.

Idempotente : ADD COLUMN IF NOT EXISTS.

Revision ID: 008
Revises: 007
Create Date: 2026-07-15
"""
from alembic import op

revision = '008'
down_revision = '007'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute(
        "ALTER TABLE docretour.declarations "
        "ADD COLUMN IF NOT EXISTS group_id UUID"
    )
    op.execute(
        "CREATE INDEX IF NOT EXISTS ix_declarations_group_id "
        "ON docretour.declarations (group_id)"
    )


def downgrade() -> None:
    op.execute("DROP INDEX IF EXISTS docretour.ix_declarations_group_id")
    op.execute("ALTER TABLE docretour.declarations DROP COLUMN IF EXISTS group_id")
