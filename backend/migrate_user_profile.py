"""
Add personal info + fcm_token columns to docretour.users.

=== HOW TO RUN ===

Option A - via Docker (recommended):
  docker exec docretour-backend python migrate_user_profile.py

Option B - local Python:
  set DATABASE_URL=postgresql+asyncpg://docretour_user:YOUR_PASS@localhost:5432/docretour_db
  python migrate_user_profile.py
"""
import asyncio
import os
import sys

_default_db_url = (
    "postgresql+asyncpg://docretour_user:change_me_in_prod_db_password"
    "@localhost:5432/docretour_db"
)
DATABASE_URL = os.getenv("DATABASE_URL", _default_db_url)

try:
    from sqlalchemy.ext.asyncio import create_async_engine
    from sqlalchemy import text
except ImportError:
    print("ERROR: sqlalchemy not installed.")
    print("Run: python -m pip install sqlalchemy asyncpg")
    sys.exit(1)


MIGRATION_SQL = """
ALTER TABLE docretour.users
  ADD COLUMN IF NOT EXISTS date_of_birth      DATE,
  ADD COLUMN IF NOT EXISTS national_id_number  VARCHAR(50),
  ADD COLUMN IF NOT EXISTS gender              VARCHAR(20),
  ADD COLUMN IF NOT EXISTS city                VARCHAR(100),
  ADD COLUMN IF NOT EXISTS region              VARCHAR(100),
  ADD COLUMN IF NOT EXISTS address             VARCHAR(255),
  ADD COLUMN IF NOT EXISTS fcm_token           VARCHAR(512);
"""


async def main() -> None:
    host_part = DATABASE_URL.split("@")[-1] if "@" in DATABASE_URL else DATABASE_URL
    print("Connecting to:", host_part)
    engine = create_async_engine(DATABASE_URL, echo=False)
    try:
        async with engine.begin() as conn:
            await conn.execute(text(MIGRATION_SQL))
        print("OK - Migration user_profile applied successfully.")
    except Exception as exc:
        print("FAILED:", exc)
        sys.exit(1)
    finally:
        await engine.dispose()


if __name__ == "__main__":
    asyncio.run(main())
