"""Endpoint d'extraction OCR/IA — proxy sécurisé vers Mistral Vision.

La clé Mistral reste côté serveur. L'app mobile envoie l'image ici plutôt que
d'appeler Mistral directement (ce qui exposerait la clé dans l'APK).
"""
import logging

import httpx
from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status

from app.core.dependencies import get_current_user
from app.models.user import User
from app.schemas.ocr import OcrExtractResponse
from app.services import ocr_service

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/ocr", tags=["ocr"])

# Limite de taille pour éviter d'envoyer des images énormes à l'IA (≈8 Mo).
_MAX_BYTES = 8 * 1024 * 1024


@router.post("/extract", response_model=OcrExtractResponse)
async def extract_document(
    image: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
):
    content = await image.read()
    if not content:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Image vide.",
        )
    if len(content) > _MAX_BYTES:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail="Image trop volumineuse (max 8 Mo).",
        )

    # IA indisponible (clé non configurée) → réponse vide, l'app bascule en
    # saisie manuelle sans erreur bloquante.
    if not ocr_service.is_available():
        logger.warning("OCR Mistral indisponible : MISTRAL_API_KEY non configurée.")
        return OcrExtractResponse(used_ai=False)

    try:
        fields = await ocr_service.extract_fields(
            content, image.content_type or "image/jpeg"
        )
        return OcrExtractResponse(**fields)
    except httpx.HTTPStatusError as exc:
        logger.error(
            "Mistral OCR a renvoyé %s : %s",
            exc.response.status_code,
            exc.response.text[:300],
        )
        # On ne bloque pas l'utilisateur : il pourra saisir manuellement.
        return OcrExtractResponse(used_ai=False)
    except Exception as exc:  # noqa: BLE001 — robustesse : jamais bloquer le scan
        logger.exception("Échec extraction OCR : %s", exc)
        return OcrExtractResponse(used_ai=False)
