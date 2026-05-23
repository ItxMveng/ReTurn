import asyncio
import logging

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import RedirectResponse

from app.api.v1.router import router as v1_router
from app.core.config import settings
from app.core.database import create_tables
from app.core.firebase_admin import init_firebase
from app.core.redis_client import close_redis
from app.core.ws_manager import redis_subscriber
import app.models  # noqa: F401 — ensures all models are registered with Base

_subscriber_task: asyncio.Task | None = None

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="DocRetour API",
    version=settings.APP_VERSION,
    description="API de restitution sécurisée de documents perdus au Cameroun.",
    docs_url="/docs",
    redoc_url="/redoc",
)

_cors_origins = settings.CORS_ORIGINS
_allow_all = settings.ENVIRONMENT != "production"

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"] if _allow_all else _cors_origins,
    allow_credentials=not _allow_all,  # credentials incompatible with wildcard origin
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(v1_router)


@app.on_event("startup")
async def startup():
    global _subscriber_task
    logger.info("Starting DocRetour API v%s [%s]", settings.APP_VERSION, settings.ENVIRONMENT)
    init_firebase()
    logger.info("Firebase Admin SDK prêt.")
    await create_tables()
    logger.info("Database tables verified.")
    _subscriber_task = asyncio.create_task(redis_subscriber(settings.REDIS_URL))
    logger.info("Redis WebSocket subscriber started.")


@app.on_event("shutdown")
async def shutdown():
    global _subscriber_task
    if _subscriber_task:
        _subscriber_task.cancel()
    await close_redis()
    logger.info("DocRetour API shutting down.")


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
