import json
from pathlib import Path
from typing import Any

from pydantic import field_validator, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

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

    # Redis
    REDIS_URL: str = "redis://localhost:6379/0"

    # MinIO
    MINIO_ENDPOINT: str
    MINIO_ROOT_USER: str
    MINIO_ROOT_PASSWORD: str
    MINIO_BUCKET_DOCUMENTS: str = "docretour-documents"
    MINIO_PUBLIC_URL: str = ""
    # Resolved at startup — use this in code
    minio_public_url: str = ""

    @model_validator(mode="after")
    def _resolve_minio_public_url(self) -> "Settings":
        import os
        # os.environ a priorité absolue sur le .env (Pydantic lit .env en dernier)
        raw = os.environ.get("MINIO_PUBLIC_URL") or self.MINIO_PUBLIC_URL
        raw = (raw or "").strip().rstrip("/")
        self.minio_public_url = raw if raw else f"http://{self.MINIO_ENDPOINT}"
        return self

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
