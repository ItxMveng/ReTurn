"""Renommage des champs ambigus + vérification adaptative + config dynamique

- Match.confirmed_by_owner            → Match.accepted_by_owner
- Match.confirmed_by_finder           → Match.accepted_by_finder
- Restitution.confirmed_by_owner      → Restitution.handoff_confirmed_by_owner
- Restitution.confirmed_by_finder     → Restitution.handoff_confirmed_by_finder
- identity_verifications : verification_level, doc_photo_url,
  rejection_reason, reviewed_at (vérification adaptative F-30)
- Nouvelle table docretour.app_config (paramètres dynamiques admin)

Idempotente : chaque RENAME est protégé par un test d'existence de colonne,
les ADD COLUMN utilisent IF NOT EXISTS.

Revision ID: 007
Revises: 006
Create Date: 2026-07-14
"""
from alembic import op

revision = '007'
down_revision = '006'
branch_labels = None
depends_on = None


def _rename_if_exists(table: str, old: str, new: str) -> None:
    op.execute(
        f"""
        DO $$
        BEGIN
            IF EXISTS (
                SELECT 1 FROM information_schema.columns
                WHERE table_schema = 'docretour'
                  AND table_name = '{table}'
                  AND column_name = '{old}'
            ) THEN
                ALTER TABLE docretour.{table} RENAME COLUMN {old} TO {new};
            END IF;
        END $$;
        """
    )


def upgrade() -> None:
    # -- Renommage des flags de confirmation ---------------------------------
    _rename_if_exists("matches", "confirmed_by_owner", "accepted_by_owner")
    _rename_if_exists("matches", "confirmed_by_finder", "accepted_by_finder")
    _rename_if_exists("restitutions", "confirmed_by_owner", "handoff_confirmed_by_owner")
    _rename_if_exists("restitutions", "confirmed_by_finder", "handoff_confirmed_by_finder")

    # -- Vérification adaptative par niveau (F-30) ----------------------------
    op.execute(
        "ALTER TABLE docretour.identity_verifications "
        "ADD COLUMN IF NOT EXISTS verification_level INTEGER NOT NULL DEFAULT 1"
    )
    op.execute(
        "ALTER TABLE docretour.identity_verifications "
        "ADD COLUMN IF NOT EXISTS doc_photo_url VARCHAR(500)"
    )
    op.execute(
        "ALTER TABLE docretour.identity_verifications "
        "ADD COLUMN IF NOT EXISTS rejection_reason VARCHAR(300)"
    )
    op.execute(
        "ALTER TABLE docretour.identity_verifications "
        "ADD COLUMN IF NOT EXISTS reviewed_at TIMESTAMPTZ"
    )

    # -- Commentaires d'évaluation post-restitution (140 chars max) -----------
    op.execute(
        "ALTER TABLE docretour.restitutions "
        "ADD COLUMN IF NOT EXISTS comment_by_owner VARCHAR(140)"
    )
    op.execute(
        "ALTER TABLE docretour.restitutions "
        "ADD COLUMN IF NOT EXISTS comment_by_finder VARCHAR(140)"
    )

    # -- Configuration dynamique (admin) --------------------------------------
    op.execute(
        """
        CREATE TABLE IF NOT EXISTS docretour.app_config (
            key VARCHAR(50) PRIMARY KEY,
            value DOUBLE PRECISION NOT NULL,
            updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
        )
        """
    )


def downgrade() -> None:
    op.execute("DROP TABLE IF EXISTS docretour.app_config")
    op.execute("ALTER TABLE docretour.restitutions DROP COLUMN IF EXISTS comment_by_finder")
    op.execute("ALTER TABLE docretour.restitutions DROP COLUMN IF EXISTS comment_by_owner")
    op.execute("ALTER TABLE docretour.identity_verifications DROP COLUMN IF EXISTS reviewed_at")
    op.execute("ALTER TABLE docretour.identity_verifications DROP COLUMN IF EXISTS rejection_reason")
    op.execute("ALTER TABLE docretour.identity_verifications DROP COLUMN IF EXISTS doc_photo_url")
    op.execute("ALTER TABLE docretour.identity_verifications DROP COLUMN IF EXISTS verification_level")
    _rename_if_exists("matches", "accepted_by_owner", "confirmed_by_owner")
    _rename_if_exists("matches", "accepted_by_finder", "confirmed_by_finder")
    _rename_if_exists("restitutions", "handoff_confirmed_by_owner", "confirmed_by_owner")
    _rename_if_exists("restitutions", "handoff_confirmed_by_finder", "confirmed_by_finder")
