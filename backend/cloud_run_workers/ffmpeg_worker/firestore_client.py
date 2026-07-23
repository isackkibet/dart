"""
Firestore client helpers for the FFmpeg worker.

Handles job claims (atomic transactions), progress updates,
completion/failure writes, and job listing.
"""

import logging
import os
from datetime import datetime, timezone

from google.cloud import firestore
from google.cloud.firestore_v1.async_client import AsyncClient

logger = logging.getLogger("firestore_client")

_db: AsyncClient | None = None

MEDIA_JOBS_COLLECTION = "mediaJobs"


def _get_db() -> AsyncClient:
    global _db
    if _db is None:
        project = os.environ.get("FIRESTORE_PROJECT_ID")
        _db = firestore.AsyncClient(project=project)
    return _db


def _now() -> datetime:
    return datetime.now(tz=timezone.utc)


async def get_job(job_id: str) -> dict | None:
    """Fetch a single mediaJob document."""
    db = _get_db()
    doc = await db.collection(MEDIA_JOBS_COLLECTION).document(job_id).get()
    if not doc.exists:
        return None
    return {"id": doc.id, **doc.to_dict()}


async def list_queued_jobs(limit: int = 4) -> list[dict]:
    """
    List queued jobs ordered by priority (desc) then createdAt (asc).
    Higher-priority jobs are processed first.
    """
    db = _get_db()
    query = (
        db.collection(MEDIA_JOBS_COLLECTION)
        .where("status", "==", "queued")
        .order_by("priority", direction=firestore.Query.DESCENDING)
        .order_by("createdAt", direction=firestore.Query.ASCENDING)
        .limit(limit)
    )
    docs = query.stream()
    return [{"id": doc.id, **doc.to_dict()} async for doc in docs]


async def claim_job(job_id: str) -> bool:
    """
    Atomically transition a job from `queued` → `processing`.
    Returns True if the claim succeeded, False if already claimed.
    """
    db = _get_db()
    ref = db.collection(MEDIA_JOBS_COLLECTION).document(job_id)

    @firestore.async_transactional
    async def _txn(transaction: firestore.AsyncTransaction) -> bool:
        snapshot = await ref.get(transaction=transaction)
        if not snapshot.exists:
            logger.warning("Job %s does not exist.", job_id)
            return False
        data = snapshot.to_dict()
        if data.get("status") != "queued":
            logger.info(
                "Job %s is no longer queued (status=%s).",
                job_id,
                data.get("status"),
            )
            return False
        transaction.update(ref, {
            "status": "processing",
            "startedAt": _now(),
            "progressPercent": 0,
            "updatedAt": _now(),
            "claimedBy": os.environ.get("HOSTNAME", "ffmpeg_worker"),
        })
        return True

    transaction = db.transaction()
    return await _txn(transaction)


async def update_job_progress(job_id: str, percent: float) -> None:
    """Write progress percentage back to Firestore."""
    db = _get_db()
    try:
        await db.collection(MEDIA_JOBS_COLLECTION).document(job_id).update({
            "progressPercent": round(percent, 1),
            "updatedAt": _now(),
        })
    except Exception as exc:  # noqa: BLE001
        logger.warning("Failed to update progress for job %s: %s", job_id, exc)


async def complete_job(job_id: str, output_ref: str) -> None:
    """Mark a job as completed with the output Cloud Storage path."""
    db = _get_db()
    await db.collection(MEDIA_JOBS_COLLECTION).document(job_id).update({
        "status": "completed",
        "outputRef": output_ref,
        "progressPercent": 100,
        "completedAt": _now(),
        "updatedAt": _now(),
        "errorMessage": None,
    })
    logger.info("Job %s marked completed → %s.", job_id, output_ref)


async def fail_job(job_id: str, error_message: str) -> None:
    """Mark a job as failed with the error message."""
    db = _get_db()
    await db.collection(MEDIA_JOBS_COLLECTION).document(job_id).update({
        "status": "failed",
        "errorMessage": error_message[:1000],  # cap message length
        "completedAt": _now(),
        "updatedAt": _now(),
    })
    logger.error("Job %s marked failed: %s", job_id, error_message)
