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
        _client = Minio(
            settings.MINIO_ENDPOINT,
            access_key=settings.MINIO_ROOT_USER,
            secret_key=settings.MINIO_ROOT_PASSWORD,
            secure=False,
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
