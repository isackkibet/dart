"""
YohPal Live — FFmpeg Worker
Cloud Run service that polls the Firestore mediaJobs queue and processes
transcode, thumbnail, clip-export, and replay-package jobs using FFmpeg.
"""

import asyncio
import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI, BackgroundTasks, HTTPException
from pydantic import BaseModel

from job_poller import poll_forever
from job_processor import process_job
from firestore_client import get_job

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger("ffmpeg_worker")

_poller_task: asyncio.Task | None = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Start background job poller on startup; cancel on shutdown."""
    global _poller_task
    logger.info("Starting FFmpeg worker — launching Firestore job poller.")
    _poller_task = asyncio.create_task(poll_forever(interval_seconds=10))
    try:
        yield
    finally:
        if _poller_task and not _poller_task.done():
            _poller_task.cancel()
            try:
                await _poller_task
            except asyncio.CancelledError:
                pass
        logger.info("FFmpeg worker shut down cleanly.")


app = FastAPI(
    title="YohPal Live — FFmpeg Worker",
    description="Cloud Run service for media processing jobs.",
    version="1.0.0",
    lifespan=lifespan,
)


# ── Health probe ──────────────────────────────────────────────────────────────
@app.get("/health")
async def health():
    return {
        "service": "yohpal-ffmpeg-worker",
        "status": "healthy",
        "poller_running": _poller_task is not None and not _poller_task.done(),
    }


# ── Manual trigger ────────────────────────────────────────────────────────────
class ProcessRequest(BaseModel):
    job_id: str


@app.post("/process")
async def trigger_process(req: ProcessRequest, background_tasks: BackgroundTasks):
    """
    Manually trigger processing of a specific mediaJob by ID.
    Used for testing and manual retries from the admin panel.
    """
    job = await get_job(req.job_id)
    if not job:
        raise HTTPException(status_code=404, detail=f"Job {req.job_id} not found.")

    logger.info("Manual trigger for job %s (type=%s)", req.job_id, job.get("jobType"))
    background_tasks.add_task(process_job, job)
    return {"queued": True, "job_id": req.job_id, "job_type": job.get("jobType")}


# ── Readiness probe ───────────────────────────────────────────────────────────
@app.get("/ready")
async def ready():
    return {"ready": True}
