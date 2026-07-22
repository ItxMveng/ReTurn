import asyncio
import uuid
from functools import partial
from io import BytesIO

from minio import Minio
from minio.error import S3Error

from app.core.config import settings

_client: Minio | None = None


def _get_client() -> Minio:
    global _client
    if _client is None:
        # Compatible MinIO (local) et tout fournisseur S3 (Cloudflare R2,
        # Backblaze B2, Wasabi…) : secure=HTTPS et region pilotés par la config.
        _client = Minio(
            settings.MINIO_ENDPOINT,
            access_key=settings.MINIO_ROOT_USER,
            secret_key=settings.MINIO_ROOT_PASSWORD,
            secure=settings.MINIO_SECURE,
            region=settings.MINIO_REGION or None,
        )
    return _client


async def ensure_bucket() -> None:
    loop = asyncio.get_event_loop()
    client = _get_client()
    bucket = settings.MINIO_BUCKET_DOCUMENTS
    found = await loop.run_in_executor(None, client.bucket_exists, bucket)
    if not found:
        await loop.run_in_executor(None, client.make_bucket, bucket)
    # Politique publique en lecture pour que les URLs soient accessibles sans auth
    import json as _json
    policy = _json.dumps({
        "Version": "2012-10-17",
        "Statement": [{
            "Effect": "Allow",
            "Principal": {"AWS": ["*"]},
            "Action": ["s3:GetObject"],
            "Resource": [f"arn:aws:s3:::{bucket}/*"]
        }]
    })
    try:
        await loop.run_in_executor(
            None,
            partial(client.set_bucket_policy, bucket, policy)
        )
    except Exception:
        pass


async def upload_photo(
    data: bytes,
    user_id: str,
    declaration_id: str,
    content_type: str = "image/jpeg",
) -> str:
    loop = asyncio.get_event_loop()
    client = _get_client()
    bucket = settings.MINIO_BUCKET_DOCUMENTS
    ext = "jpg" if "jpeg" in content_type else content_type.split("/")[-1]
    object_name = f"{user_id}/{declaration_id}/{uuid.uuid4().hex}.{ext}"

    await loop.run_in_executor(
        None,
        partial(
            client.put_object,
            bucket,
            object_name,
            BytesIO(data),
            len(data),
            content_type=content_type,
        ),
    )
    return f"{settings.minio_public_url}/{bucket}/{object_name}"


async def get_object(bucket: str, object_name: str) -> tuple[bytes, str]:
    """Récupère un objet MinIO (contenu + content-type) pour le proxy média.

    Le proxy backend sert les images à l'app : celle-ci atteint toujours le
    backend (IP auto-détectée), alors que l'URL publique MinIO peut pointer
    vers un hôte injoignable depuis le téléphone.
    """
    loop = asyncio.get_event_loop()
    client = _get_client()
    response = await loop.run_in_executor(
        None, partial(client.get_object, bucket, object_name)
    )
    try:
        data = response.read()
        content_type = response.headers.get("Content-Type", "application/octet-stream")
    finally:
        response.close()
        response.release_conn()
    return data, content_type


async def delete_photo(url: str) -> None:
    try:
        loop = asyncio.get_event_loop()
        client = _get_client()
        bucket = settings.MINIO_BUCKET_DOCUMENTS
        object_name = url.split(f"{bucket}/", 1)[-1]
        await loop.run_in_executor(
            None, partial(client.remove_object, bucket, object_name)
        )
    except S3Error:
        pass
