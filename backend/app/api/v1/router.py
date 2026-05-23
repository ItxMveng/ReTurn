from fastapi import APIRouter

from app.api.v1.endpoints import auth, declarations, matches, messaging, profile

router = APIRouter(prefix="/api/v1")

router.include_router(auth.router)
router.include_router(profile.router)
router.include_router(declarations.router)
router.include_router(matches.router)
router.include_router(messaging.router)


@router.get("/ping", tags=["health"])
async def ping():
    return {"message": "pong", "sprint": "S4"}
