from app.core.config import normalize_database_url


def test_neon_url_is_converted_for_asyncpg():
    url = (
        "postgresql://user:pw@ep-x-pooler.eu-central-1.aws.neon.tech/neondb"
        "?sslmode=require&channel_binding=require"
    )
    assert normalize_database_url(url) == (
        "postgresql+asyncpg://user:pw@ep-x-pooler.eu-central-1.aws.neon.tech/neondb"
        "?ssl=require"
    )


def test_render_style_scheme_is_converted():
    assert (
        normalize_database_url("postgres://u:p@host/db")
        == "postgresql+asyncpg://u:p@host/db"
    )


def test_already_normalized_or_other_drivers_are_untouched():
    for url in (
        "sqlite+aiosqlite:///:memory:",
        "postgresql+asyncpg://u:p@localhost:5432/db",
        "postgresql+asyncpg://u:p@localhost:5432/db?ssl=require",
    ):
        assert normalize_database_url(url) == url
