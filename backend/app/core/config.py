import json
from pathlib import Path
from typing import Any
from urllib.parse import parse_qsl, urlencode, urlsplit, urlunsplit

from pydantic import field_validator, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

# Paramètres de connexion libpq qu'asyncpg ne supporte pas.
_LIBPQ_ONLY_PARAMS = {"channel_binding", "gssencmode", "target_session_attrs"}


def normalize_database_url(url: str) -> str:
    """postgres(ql)://…?sslmode=require → postgresql+asyncpg://…?ssl=require."""
    if url.startswith("postgres://"):
        url = "postgresql+asyncpg://" + url[len("postgres://"):]
    elif url.startswith("postgresql://"):
        url = "postgresql+asyncpg://" + url[len("postgresql://"):]
    if not url.startswith("postgresql+asyncpg://"):
        return url

    parts = urlsplit(url)
    query = []
    for key, val in parse_qsl(parts.query, keep_blank_values=True):
        if key in _LIBPQ_ONLY_PARAMS:
            continue
        query.append(("ssl" if key == "sslmode" else key, val))
    return urlunsplit(parts._replace(query=urlencode(query)))


BACKEND_DIR = Path(__file__).resolve().parents[2]
REPO_ROOT = BACKEND_DIR.parent
ENV_FILES = tuple(
    str(path)
    for path in (
        BACKEND_DIR / ".env",
        REPO_ROOT / ".env",
        REPO_ROOT / "infra" / ".env",
    )
)


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=ENV_FILES,
        case_sensitive=True,
        extra="ignore",
    )

    # App
    APP_NAME: str = "DocRetour"
    APP_VERSION: str = "0.1.0"
    ENVIRONMENT: str = "development"
    DEBUG: bool = True

    # Security
    SECRET_KEY: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 15
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7

    # Database
    DATABASE_URL: str

    @field_validator("DATABASE_URL", mode="before")
    @classmethod
    def _force_asyncpg_driver(cls, value: Any) -> Any:
        """Force le driver asyncpg et adapte les paramètres libpq.

        Les hébergeurs (Render, Neon…) fournissent l'URL au format
        `postgres://…` ou `postgresql://…` avec des paramètres libpq
        (`sslmode`, `channel_binding`) que SQLAlchemy async / asyncpg ne
        comprennent pas. On normalise pour que l'app ET Alembic fonctionnent
        avec l'URL collée telle quelle depuis la console de l'hébergeur.
        """
        if isinstance(value, str):
            return normalize_database_url(value)
        return value

    # Redis
    REDIS_URL: str = "redis://localhost:6379/0"

    # Stockage objet — compatible S3 (MinIO en local, Cloudflare R2 / Backblaze
    # B2 / Wasabi en production). En prod : MINIO_SECURE=true + MINIO_REGION.
    MINIO_ENDPOINT: str
    MINIO_ROOT_USER: str
    MINIO_ROOT_PASSWORD: str
    MINIO_BUCKET_DOCUMENTS: str = "docretour-documents"
    MINIO_PUBLIC_URL: str = ""
    MINIO_SECURE: bool = False          # true derrière R2/B2 (HTTPS)
    MINIO_REGION: str = ""              # "auto" pour R2, ex. "us-east-005" pour B2
    # Resolved at startup — use this in code
    minio_public_url: str = ""

    @field_validator("MINIO_SECURE", mode="before")
    @classmethod
    def _parse_minio_secure(cls, value: Any) -> bool:
        if isinstance(value, bool):
            return value
        if isinstance(value, str):
            return value.strip().lower() in {"1", "true", "yes", "on"}
        return bool(value)

    @model_validator(mode="after")
    def _resolve_minio_public_url(self) -> "Settings":
        import os
        # os.environ a priorité absolue sur le .env (Pydantic lit .env en dernier)
        raw = os.environ.get("MINIO_PUBLIC_URL") or self.MINIO_PUBLIC_URL
        raw = (raw or "").strip().rstrip("/")
        self.minio_public_url = raw if raw else f"http://{self.MINIO_ENDPOINT}"
        return self

    # Mistral AI (OCR / extraction de champs) — clé gardée côté serveur,
    # jamais embarquée dans l'APK mobile. L'app appelle /api/v1/ocr/extract.
    MISTRAL_API_KEY: str = ""

    # Administrateurs déclarés par configuration (sans shell) : numéros E.164
    # séparés par des virgules. À chaque connexion, ces numéros sont promus
    # admin automatiquement. Ex. ADMIN_PHONE_NUMBERS="+237690000000,+237680000000"
    ADMIN_PHONE_NUMBERS: str = ""
    # Secret de connexion au panneau d'admin (numéro + secret, sans SMS).
    # À définir dans l'environnement de prod ; connu de toi seul.
    ADMIN_BOOTSTRAP_SECRET: str = ""

    @property
    def admin_phone_set(self) -> set[str]:
        return {
            p.strip().replace(" ", "")
            for p in self.ADMIN_PHONE_NUMBERS.split(",")
            if p.strip()
        }

    # Firebase Admin SDK
    FIREBASE_SERVICE_ACCOUNT_JSON_BASE64: str = ""
    FIREBASE_MOCK_MODE: bool = False
    FIREBASE_MOCK_TEST_PHONE: str = "+237600000000"
    FIREBASE_MOCK_TEST_CODE: str = "123456"

    # CORS — accepts either a JSON string or a list
    CORS_ORIGINS: list[str] = ["http://localhost:3000", "http://localhost:8080"]

    @field_validator("CORS_ORIGINS", mode="before")
    @classmethod
    def parse_cors_origins(cls, value: Any) -> list[str]:
        if isinstance(value, str):
            return json.loads(value)
        return value

    @field_validator("DEBUG", mode="before")
    @classmethod
    def parse_debug(cls, value: Any) -> bool:
        if isinstance(value, bool):
            return value
        if isinstance(value, str):
            normalized = value.strip().lower()
            if normalized in {"1", "true", "yes", "on", "debug", "development"}:
                return True
            if normalized in {"0", "false", "no", "off", "release", "production"}:
                return False
        return bool(value)


settings = Settings()
