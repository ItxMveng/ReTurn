from fastapi import APIRouter
from app.api.v1.endpoints import (
    auth,
    declarations,
    matches,
    media,
    messaging,
    ocr,
    profile,
    restitutions,
    zones,
    admin,
    reports,
)

router = APIRouter(prefix="/api/v1")

router.include_router(auth.router)
router.include_router(profile.router)
router.include_router(declarations.router)
router.include_router(matches.router)
router.include_router(restitutions.router)
router.include_router(messaging.router)
router.include_router(zones.router)
router.include_router(ocr.router)
router.include_router(reports.router)
router.include_router(media.router)
router.include_router(admin.router)
