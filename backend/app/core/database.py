import logging

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import DeclarativeBase, sessionmaker

from app.core.config import settings

logger = logging.getLogger(__name__)

# pool_pre_ping : Neon suspend son compute après quelques minutes d'inactivité
# et coupe les connexions ; on teste chaque connexion avant usage plutôt que
# de servir une erreur sur la première requête après le réveil.
engine = create_async_engine(
    settings.DATABASE_URL,
    echo=settings.DEBUG,
    future=True,
    pool_pre_ping=True,
    pool_recycle=300,
)

AsyncSessionLocal = sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
)


class Base(DeclarativeBase):
    pass


async def get_db():
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise


async def create_tables() -> None:
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)


# Colonnes ajoutées par les migrations 002+ que `create_all` n'applique PAS aux
# tables déjà existantes. On les (re)met de façon idempotente au démarrage pour
# éviter les 500 « column ... does not exist » sans exiger d'alembic ni perdre
# de données.
_SCHEMA_FIXES = (
    "ALTER TABLE docretour.declarations ADD COLUMN IF NOT EXISTS event_date DATE",
    "ALTER TABLE docretour.users ADD COLUMN IF NOT EXISTS "
    "score_reputation DOUBLE PRECISION NOT NULL DEFAULT 5.0",
    "ALTER TABLE docretour.users ALTER COLUMN phone_number DROP NOT NULL",
    "ALTER TABLE docretour.identity_verifications ADD COLUMN IF NOT EXISTS "
    "questions_passed BOOLEAN NOT NULL DEFAULT FALSE",
    # Migration 007 — renommage des champs ambigus (confirmed_by_* → accepted_by_* /
    # handoff_confirmed_by_*). Les RENAME échouent sans conséquence si déjà appliqués
    # (le try/except de reconcile_schema les ignore).
    "ALTER TABLE docretour.matches RENAME COLUMN confirmed_by_owner TO accepted_by_owner",
    "ALTER TABLE docretour.matches RENAME COLUMN confirmed_by_finder TO accepted_by_finder",
    "ALTER TABLE docretour.restitutions RENAME COLUMN confirmed_by_owner "
    "TO handoff_confirmed_by_owner",
    "ALTER TABLE docretour.restitutions RENAME COLUMN confirmed_by_finder "
    "TO handoff_confirmed_by_finder",
    "ALTER TABLE docretour.matches ADD COLUMN IF NOT EXISTS "
    "accepted_by_owner BOOLEAN NOT NULL DEFAULT FALSE",
    "ALTER TABLE docretour.matches ADD COLUMN IF NOT EXISTS "
    "accepted_by_finder BOOLEAN NOT NULL DEFAULT FALSE",
    "ALTER TABLE docretour.restitutions ADD COLUMN IF NOT EXISTS "
    "handoff_confirmed_by_owner BOOLEAN NOT NULL DEFAULT FALSE",
    "ALTER TABLE docretour.restitutions ADD COLUMN IF NOT EXISTS "
    "handoff_confirmed_by_finder BOOLEAN NOT NULL DEFAULT FALSE",
    "ALTER TABLE docretour.restitutions ADD COLUMN IF NOT EXISTS "
    "comment_by_owner VARCHAR(140)",
    "ALTER TABLE docretour.restitutions ADD COLUMN IF NOT EXISTS "
    "comment_by_finder VARCHAR(140)",
    # Migration 007 — vérification adaptative par niveau (F-30)
    "ALTER TABLE docretour.identity_verifications ADD COLUMN IF NOT EXISTS "
    "verification_level INTEGER NOT NULL DEFAULT 1",
    "ALTER TABLE docretour.identity_verifications ADD COLUMN IF NOT EXISTS "
    "doc_photo_url VARCHAR(500)",
    "ALTER TABLE docretour.identity_verifications ADD COLUMN IF NOT EXISTS "
    "rejection_reason VARCHAR(300)",
    "ALTER TABLE docretour.identity_verifications ADD COLUMN IF NOT EXISTS "
    "reviewed_at TIMESTAMPTZ",
    # Migration 008 — dossiers multi-documents
    "ALTER TABLE docretour.declarations ADD COLUMN IF NOT EXISTS group_id UUID",
    "CREATE INDEX IF NOT EXISTS ix_declarations_group_id "
    "ON docretour.declarations (group_id)",
    # Migration 009 — support multi-pays (sans backfill : reconcile tourne à
    # chaque démarrage, un UPDATE écraserait les pays « inconnus »).
    "ALTER TABLE docretour.users ADD COLUMN IF NOT EXISTS country_code VARCHAR(2)",
    "ALTER TABLE docretour.declarations ADD COLUMN IF NOT EXISTS "
    "country_code VARCHAR(2)",
    "ALTER TABLE docretour.zones_recuperation ADD COLUMN IF NOT EXISTS "
    "country_code VARCHAR(2)",
    "CREATE INDEX IF NOT EXISTS ix_declarations_country_code "
    "ON docretour.declarations (country_code)",
    "CREATE INDEX IF NOT EXISTS ix_zones_recuperation_country_code "
    "ON docretour.zones_recuperation (country_code)",
)


async def reconcile_schema() -> None:
    """Aligne le schéma existant sur les modèles (idempotent, sans perte)."""
    for stmt in _SCHEMA_FIXES:
        try:
            async with engine.begin() as conn:
                await conn.execute(text(stmt))
        except Exception as exc:  # noqa: BLE001
            logger.warning("Schema reconcile ignoré: %s (%s)", stmt, exc)
