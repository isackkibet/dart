"""
Google Cloud Storage helpers for the FFmpeg worker.

Provides async-friendly wrappers around the GCS client for
downloading input files and uploading processed output files.
"""

import asyncio
import logging
import os
from functools import partial
from pathlib import Path

from google.cloud import storage

logger = logging.getLogger("storage_client")

_client: storage.Client | None = None


def _get_client() -> storage.Client:
    global _client
    if _client is None:
        _client = storage.Client()
    return _client


def _parse_gs_path(gs_path: str) -> tuple[str, str]:
    """Parse 'gs://bucket/path/to/blob' → (bucket, blob_name)."""
    if not gs_path.startswith("gs://"):
        raise ValueError(f"Invalid GCS path: {gs_path!r}. Must start with 'gs://'.")
    without_prefix = gs_path[5:]
    bucket, _, blob_name = without_prefix.partition("/")
    return bucket, blob_name


async def download_blob(gs_path: str, local_path: str) -> None:
    """
    Download a blob from GCS to a local file path.
    Runs the blocking GCS download in a thread pool to avoid blocking the event loop.
    """
    bucket_name, blob_name = _parse_gs_path(gs_path)
    logger.info("Downloading gs://%s/%s → %s", bucket_name, blob_name, local_path)

    loop = asyncio.get_running_loop()
    await loop.run_in_executor(
        None,
        partial(_sync_download, bucket_name, blob_name, local_path),
    )
    logger.info("Download complete: %s", local_path)


def _sync_download(bucket_name: str, blob_name: str, local_path: str) -> None:
    client = _get_client()
    bucket = client.bucket(bucket_name)
    blob = bucket.blob(blob_name)
    Path(local_path).parent.mkdir(parents=True, exist_ok=True)
    blob.download_to_filename(local_path)


async def upload_blob(local_path: str, gs_path: str) -> None:
    """
    Upload a local file to GCS.
    Runs the blocking GCS upload in a thread pool.
    """
    bucket_name, blob_name = _parse_gs_path(gs_path)
    logger.info("Uploading %s → gs://%s/%s", local_path, bucket_name, blob_name)

    loop = asyncio.get_running_loop()
    await loop.run_in_executor(
        None,
        partial(_sync_upload, bucket_name, blob_name, local_path),
    )
    logger.info("Upload complete: gs://%s/%s", bucket_name, blob_name)


def _sync_upload(bucket_name: str, blob_name: str, local_path: str) -> None:
    client = _get_client()
    bucket = client.bucket(bucket_name)
    blob = bucket.blob(blob_name)
    content_type = _guess_content_type(local_path)
    blob.upload_from_filename(local_path, content_type=content_type)


def _guess_content_type(path: str) -> str:
    ext = Path(path).suffix.lower()
    return {
        ".mp4": "video/mp4",
        ".webm": "video/webm",
        ".jpg": "image/jpeg",
        ".jpeg": "image/jpeg",
        ".png": "image/png",
        ".m3u8": "application/x-mpegURL",
        ".ts": "video/MP2T",
    }.get(ext, "application/octet-stream")


async def get_signed_url(gs_path: str, expiry_minutes: int = 60) -> str:
    """
    Generate a signed URL for temporary public access to a GCS blob.
    Requires the service account to have the `roles/iam.serviceAccountTokenCreator` role.
    """
    import datetime

    bucket_name, blob_name = _parse_gs_path(gs_path)
    loop = asyncio.get_running_loop()

    def _sign():
        client = _get_client()
        bucket = client.bucket(bucket_name)
        blob = bucket.blob(blob_name)
        return blob.generate_signed_url(
            version="v4",
            expiration=datetime.timedelta(minutes=expiry_minutes),
            method="GET",
        )

    url = await loop.run_in_executor(None, _sign)
    logger.info("Generated signed URL for gs://%s/%s (expires %dm)", bucket_name, blob_name, expiry_minutes)
    return url
