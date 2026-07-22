"""Proxy média — sert les fichiers stockés dans MinIO via le backend.

L'app mobile atteint toujours le backend (IP auto-détectée au lancement),
alors que l'URL publique MinIO peut pointer vers un hôte injoignable depuis
le téléphone. Ce proxy garantit que les images se chargent partout, sans
dépendre de la configuration réseau de MinIO. Accès public en lecture seule
(les buckets sont déjà en lecture publique).
"""
from fastapi import APIRouter, HTTPException, Response, status

from app.services import storage_service

router = APIRouter(prefix="/media", tags=["media"])

_CACHE_HEADERS = {"Cache-Control": "public, max-age=86400"}


@router.get("/{bucket}/{object_path:path}")
async def get_media(bucket: str, object_path: str):
    try:
        data, content_type = await storage_service.get_object(bucket, object_path)
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Fichier introuvable",
        )
    return Response(content=data, media_type=content_type, headers=_CACHE_HEADERS)
