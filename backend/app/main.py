import asyncio
import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, RedirectResponse

from app.api.v1.router import router as v1_router
from app.core.config import settings
from app.core.database import create_tables, reconcile_schema
from app.core.firebase_admin import init_firebase
from app.core.redis_client import close_redis
from app.core.ws_manager import redis_subscriber
import app.models  # noqa: F401 — ensures all models are registered with Base

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

_subscriber_task: asyncio.Task | None = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Manage application startup and shutdown lifecycle."""
    global _subscriber_task
    logger.info(
        "Starting DocRetour API v%s [%s]",
        settings.APP_VERSION,
        settings.ENVIRONMENT,
    )
    init_firebase()
    logger.info("Firebase Admin SDK ready.")
    await create_tables()
    await reconcile_schema()
    logger.info("Database tables verified.")
    _subscriber_task = asyncio.create_task(
        redis_subscriber(settings.REDIS_URL)
    )
    logger.info("Redis WebSocket subscriber started.")

    yield  # <-- app is running

    if _subscriber_task:
        _subscriber_task.cancel()
        try:
            await _subscriber_task
        except asyncio.CancelledError:
            pass
    await close_redis()
    logger.info("DocRetour API shut down cleanly.")


app = FastAPI(
    title="DocRetour API",
    version=settings.APP_VERSION,
    description="API de restitution sécurisée de documents perdus au Cameroun.",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan,
)

_cors_origins = settings.CORS_ORIGINS
_is_prod = settings.ENVIRONMENT == "production"

app.add_middleware(
    CORSMiddleware,
    # Non-prod: accept all origins + explicit "null" (file:// admin panel)
    allow_origins=_cors_origins if _is_prod else ["*", "null"],
    allow_credentials=_is_prod,  # wildcard origin is incompatible with credentials
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(v1_router)


@app.exception_handler(Exception)
async def _unhandled_exception_handler(request: Request, exc: Exception):
    """Renvoie une 500 JSON qui PASSE par le middleware CORS.

    Par défaut, une exception non gérée est interceptée hors de la chaîne CORS
    → la réponse 500 n'a pas d'en-tête Access-Control-Allow-Origin, et le
    navigateur affiche « CORS missing header » au lieu de la vraie erreur.
    Ce handler la renvoie proprement (avec CORS) et la loggue côté serveur.
    """
    logger.exception("Erreur non gérée sur %s %s", request.method, request.url.path)
    return JSONResponse(
        status_code=500,
        content={"detail": "Erreur serveur interne."},
    )


@app.get("/health", tags=["health"])
async def health():
    return {
        "status": "healthy",
        "version": settings.APP_VERSION,
        "environment": settings.ENVIRONMENT,
    }


@app.get("/", include_in_schema=False)
async def root():
    return RedirectResponse(url="/docs")
