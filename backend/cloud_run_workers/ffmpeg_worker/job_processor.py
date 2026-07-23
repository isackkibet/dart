"""
Core job processor — routes jobs to the correct FFmpeg handler.
"""

import logging
import os
import tempfile
import uuid
from pathlib import Path

from ffmpeg_runner import run_transcode, run_thumbnail, run_clip_trim
from firestore_client import update_job_progress, complete_job, fail_job
from storage_client import download_blob, upload_blob

logger = logging.getLogger("job_processor")

TEMP_DIR = Path(os.environ.get("TEMP_DIR", "/tmp/yohpal_worker"))
TEMP_DIR.mkdir(parents=True, exist_ok=True)

GCS_BUCKET = os.environ.get("GCS_BUCKET_NAME", "yohpal-live")


def _local_path(filename: str) -> Path:
    return TEMP_DIR / filename


def _output_gs_path(job_id: str, filename: str) -> str:
    return f"gs://{GCS_BUCKET}/processed/{job_id}/{filename}"


async def process_job(job: dict) -> None:
    """Route a claimed job to the appropriate handler."""
    job_id: str = job.get("id", "")
    job_type: str = job.get("jobType", "")
    logger.info("Processing job %s (type=%s)", job_id, job_type)

    try:
        if job_type == "transcode":
            await handle_transcode(job)
        elif job_type == "thumbnail":
            await handle_thumbnail(job)
        elif job_type == "clip_export":
            await handle_clip_export(job)
        elif job_type == "replay_package":
            await handle_replay_package(job)
        else:
            raise ValueError(f"Unknown job type: {job_type}")
    except Exception as exc:  # noqa: BLE001
        logger.exception("Job %s failed: %s", job_id, exc)
        await fail_job(job_id, str(exc))


# ── Transcode ─────────────────────────────────────────────────────────────────
async def handle_transcode(job: dict) -> None:
    job_id = job["id"]
    config = job.get("config", {})
    input_gs = job.get("inputRef", "")
    work_id = str(uuid.uuid4())[:8]

    local_input = _local_path(f"{work_id}_input.mp4")
    local_output = _local_path(f"{work_id}_output.{config.get('outputFormat', 'mp4')}")
    output_gs = _output_gs_path(job_id, f"transcode.{config.get('outputFormat', 'mp4')}")

    try:
        await update_job_progress(job_id, 5)
        logger.info("Downloading %s → %s", input_gs, local_input)
        await download_blob(input_gs, str(local_input))

        await update_job_progress(job_id, 15)
        logger.info("Running transcode for job %s", job_id)
        await run_transcode(str(local_input), str(local_output), config)

        await update_job_progress(job_id, 85)
        logger.info("Uploading %s → %s", local_output, output_gs)
        await upload_blob(str(local_output), output_gs)

        await complete_job(job_id, output_gs)
        logger.info("Job %s completed (transcode).", job_id)
    finally:
        _cleanup(local_input, local_output)


# ── Thumbnail ─────────────────────────────────────────────────────────────────
async def handle_thumbnail(job: dict) -> None:
    job_id = job["id"]
    input_gs = job.get("inputRef", "")
    # Use clip start offset as thumbnail timestamp if available
    offset_seconds: int = (
        job.get("clipStartOffsetSeconds") or
        job.get("thumbnailOffsetSeconds") or
        0
    )
    work_id = str(uuid.uuid4())[:8]
    local_input = _local_path(f"{work_id}_input.mp4")
    local_output = _local_path(f"{work_id}_thumb.jpg")
    output_gs = _output_gs_path(job_id, "thumbnail.jpg")

    try:
        await update_job_progress(job_id, 5)
        await download_blob(input_gs, str(local_input))

        await update_job_progress(job_id, 40)
        await run_thumbnail(str(local_input), str(local_output), offset_seconds)

        await update_job_progress(job_id, 80)
        await upload_blob(str(local_output), output_gs)

        await complete_job(job_id, output_gs)
        logger.info("Job %s completed (thumbnail).", job_id)
    finally:
        _cleanup(local_input, local_output)


# ── Clip export ───────────────────────────────────────────────────────────────
async def handle_clip_export(job: dict) -> None:
    job_id = job["id"]
    config = job.get("config", {})
    input_gs = job.get("inputRef", "")
    start_s: int = job.get("startOffsetSeconds", 0)
    end_s: int = job.get("endOffsetSeconds", 60)
    work_id = str(uuid.uuid4())[:8]

    ext = config.get("outputFormat", "mp4")
    local_input = _local_path(f"{work_id}_input.mp4")
    local_output = _local_path(f"{work_id}_clip.{ext}")
    output_gs = _output_gs_path(job_id, f"clip.{ext}")

    try:
        await update_job_progress(job_id, 5)
        await download_blob(input_gs, str(local_input))

        await update_job_progress(job_id, 20)
        await run_clip_trim(str(local_input), str(local_output), start_s, end_s, config)

        await update_job_progress(job_id, 80)
        await upload_blob(str(local_output), output_gs)

        await complete_job(job_id, output_gs)
        logger.info("Job %s completed (clip_export).", job_id)
    finally:
        _cleanup(local_input, local_output)


# ── Replay package ────────────────────────────────────────────────────────────
async def handle_replay_package(job: dict) -> None:
    """
    Package a full session replay with the given config.
    Essentially a full transcode with replay-specific output naming.
    """
    job_id = job["id"]
    config = job.get("config", {})
    input_gs = job.get("inputRef", "")
    work_id = str(uuid.uuid4())[:8]

    ext = config.get("outputFormat", "mp4")
    local_input = _local_path(f"{work_id}_input.mp4")
    local_output = _local_path(f"{work_id}_replay.{ext}")
    session_id = job.get("sessionId", job_id)
    output_gs = f"gs://{GCS_BUCKET}/replays/processed/{session_id}.{ext}"

    try:
        await update_job_progress(job_id, 5)
        await download_blob(input_gs, str(local_input))

        await update_job_progress(job_id, 15)
        await run_transcode(str(local_input), str(local_output), config)

        await update_job_progress(job_id, 85)
        await upload_blob(str(local_output), output_gs)

        await complete_job(job_id, output_gs)
        logger.info("Job %s completed (replay_package).", job_id)
    finally:
        _cleanup(local_input, local_output)


# ── Helpers ───────────────────────────────────────────────────────────────────
def _cleanup(*paths: Path) -> None:
    for p in paths:
        try:
            if p.exists():
                p.unlink()
        except Exception:  # noqa: BLE001
            pass
