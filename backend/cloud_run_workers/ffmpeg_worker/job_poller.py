"""
Firestore job queue poller.

Continuously polls the `mediaJobs` collection for `queued` jobs, claims them
atomically (queued → processing), and dispatches them to the job processor.
"""

import asyncio
import logging

from firestore_client import claim_job, list_queued_jobs
from job_processor import process_job

logger = logging.getLogger("job_poller")

# Maximum jobs to run concurrently per worker instance
MAX_CONCURRENT_JOBS = 2
_semaphore: asyncio.Semaphore | None = None


def _get_semaphore() -> asyncio.Semaphore:
    global _semaphore
    if _semaphore is None:
        _semaphore = asyncio.Semaphore(MAX_CONCURRENT_JOBS)
    return _semaphore


async def _run_job_safe(job: dict) -> None:
    """Claim and process a job under the concurrency semaphore."""
    async with _get_semaphore():
        job_id = job.get("id") or job.get("__id")
        if not job_id:
            logger.warning("Job missing ID, skipping: %s", job)
            return

        claimed = await claim_job(job_id)
        if not claimed:
            logger.info("Job %s was already claimed by another worker, skipping.", job_id)
            return

        logger.info("Claimed job %s (type=%s).", job_id, job.get("jobType"))
        try:
            await process_job({**job, "id": job_id})
        except Exception as exc:  # noqa: BLE001
            logger.exception("Unhandled error processing job %s: %s", job_id, exc)


async def poll_once() -> int:
    """
    Poll Firestore for queued jobs and dispatch them.
    Returns the number of jobs dispatched.
    """
    queued = await list_queued_jobs(limit=MAX_CONCURRENT_JOBS * 2)
    if not queued:
        return 0

    tasks = [asyncio.create_task(_run_job_safe(job)) for job in queued]
    await asyncio.gather(*tasks, return_exceptions=True)
    return len(tasks)


async def poll_forever(interval_seconds: int = 10) -> None:
    """
    Infinite polling loop. Runs poll_once every `interval_seconds`.
    Designed to run as a background asyncio task.
    """
    logger.info("Job poller started (interval=%ds, max_concurrent=%d).",
                interval_seconds, MAX_CONCURRENT_JOBS)
    while True:
        try:
            count = await poll_once()
            if count:
                logger.info("Dispatched %d job(s) this cycle.", count)
        except asyncio.CancelledError:
            logger.info("Job poller cancelled — shutting down.")
            raise
        except Exception as exc:  # noqa: BLE001
            logger.exception("Poller encountered an error: %s. Continuing.", exc)
        await asyncio.sleep(interval_seconds)
