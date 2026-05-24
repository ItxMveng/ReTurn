from fastapi import APIRouter
from app.api.v1.endpoints import (
    auth,
    declarations,
    matches,
    messaging,
    profile,
    restitutions,
    admin,
)

api_router = APIRouter(prefix="/api/v1")

api_router.include_router(auth.router)
api_router.include_router(profile.router)
api_router.include_router(declarations.router)
api_router.include_router(matches.router)
api_router.include_router(restitutions.router)
api_router.include_router(messaging.router)
api_router.include_router(admin.router)
