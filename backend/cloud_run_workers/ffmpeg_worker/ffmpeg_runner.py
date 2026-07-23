"""
FFmpeg subprocess wrapper.

Builds FFmpeg command arguments from PipelineConfig and executes
transcoding, thumbnail extraction, and clip trimming operations.
"""

import asyncio
import logging
import re
import shutil
from typing import Any

logger = logging.getLogger("ffmpeg_runner")

# Resolution → width×height map
RESOLUTION_MAP = {
    "1080p": (1920, 1080),
    "720p": (1280, 720),
    "480p": (854, 480),
    "360p": (640, 360),
}


def _ffmpeg_path() -> str:
    path = shutil.which("ffmpeg")
    if not path:
        raise RuntimeError(
            "FFmpeg not found in PATH. "
            "Ensure FFmpeg is installed in the container."
        )
    return path


def _build_transcode_args(
    input_path: str,
    output_path: str,
    config: dict[str, Any],
) -> list[str]:
    """Build FFmpeg arguments for transcoding."""
    resolution = config.get("resolution", "720p")
    w, h = RESOLUTION_MAP.get(resolution, (1280, 720))
    video_bitrate = config.get("videoBitrate", 2500)
    audio_bitrate = config.get("audioBitrate", 128)
    fps = config.get("fps", 30)
    output_format = config.get("outputFormat", "mp4")
    watermark_ref = config.get("watermarkRef")
    watermark_enabled = config.get("watermarkEnabled", False)

    args = [
        _ffmpeg_path(),
        "-y",                          # overwrite output
        "-i", input_path,
    ]

    # Watermark overlay
    if watermark_enabled and watermark_ref:
        # watermarkRef is a local path after download
        args += ["-i", watermark_ref]
        vf = (
            f"scale={w}:{h}:force_original_aspect_ratio=decrease,"
            f"pad={w}:{h}:(ow-iw)/2:(oh-ih)/2,"
            f"[0:v][1:v]overlay=W-w-10:H-h-10"
        )
        args += ["-filter_complex", vf]
    else:
        vf = (
            f"scale={w}:{h}:force_original_aspect_ratio=decrease,"
            f"pad={w}:{h}:(ow-iw)/2:(oh-ih)/2"
        )
        args += ["-vf", vf]

    args += [
        "-c:v", "libx264",
        "-b:v", f"{video_bitrate}k",
        "-r", str(fps),
        "-c:a", "aac",
        "-b:a", f"{audio_bitrate}k",
        "-movflags", "+faststart",
        "-preset", "fast",
    ]

    if output_format == "webm":
        args[args.index("libx264")] = "libvpx-vp9"
        args[args.index("aac")] = "libopus"

    args.append(output_path)
    return args


async def run_transcode(
    input_path: str,
    output_path: str,
    config: dict[str, Any],
) -> None:
    """Run FFmpeg transcoding and stream progress from stderr."""
    args = _build_transcode_args(input_path, output_path, config)
    logger.info("FFmpeg transcode: %s", " ".join(args))
    await _run_ffmpeg(args, label="transcode")


async def run_thumbnail(
    input_path: str,
    output_path: str,
    offset_seconds: int = 0,
) -> None:
    """Extract a single frame at the given offset as a JPEG thumbnail."""
    args = [
        _ffmpeg_path(),
        "-y",
        "-ss", str(offset_seconds),
        "-i", input_path,
        "-vframes", "1",
        "-q:v", "2",
        "-f", "image2",
        output_path,
    ]
    logger.info("FFmpeg thumbnail at %ds: %s", offset_seconds, " ".join(args))
    await _run_ffmpeg(args, label="thumbnail")


async def run_clip_trim(
    input_path: str,
    output_path: str,
    start_seconds: int,
    end_seconds: int,
    config: dict[str, Any],
) -> None:
    """Trim a clip segment from start_seconds to end_seconds."""
    duration = end_seconds - start_seconds
    resolution = config.get("resolution", "720p")
    w, h = RESOLUTION_MAP.get(resolution, (1280, 720))
    video_bitrate = config.get("videoBitrate", 2500)
    audio_bitrate = config.get("audioBitrate", 128)

    args = [
        _ffmpeg_path(),
        "-y",
        "-ss", str(start_seconds),
        "-i", input_path,
        "-t", str(duration),
        "-vf", f"scale={w}:{h}:force_original_aspect_ratio=decrease,pad={w}:{h}:(ow-iw)/2:(oh-ih)/2",
        "-c:v", "libx264",
        "-b:v", f"{video_bitrate}k",
        "-c:a", "aac",
        "-b:a", f"{audio_bitrate}k",
        "-movflags", "+faststart",
        "-preset", "fast",
        output_path,
    ]
    logger.info(
        "FFmpeg clip trim [%ds → %ds]: %s",
        start_seconds, end_seconds, " ".join(args),
    )
    await _run_ffmpeg(args, label="clip_trim")


async def _run_ffmpeg(args: list[str], label: str = "ffmpeg") -> None:
    """
    Execute FFmpeg as an async subprocess. Streams stderr line-by-line
    and parses `time=HH:MM:SS` for progress logging.
    """
    process = await asyncio.create_subprocess_exec(
        *args,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE,
    )

    # Stream stderr for progress info
    assert process.stderr is not None
    async for line in process.stderr:
        decoded = line.decode("utf-8", errors="replace").strip()
        if "time=" in decoded:
            match = re.search(r"time=(\d+:\d+:\d+\.\d+)", decoded)
            if match:
                logger.debug("[%s] progress: %s", label, match.group(1))
        elif decoded:
            logger.debug("[%s] %s", label, decoded)

    await process.wait()

    if process.returncode != 0:
        raise RuntimeError(
            f"FFmpeg {label} exited with code {process.returncode}."
        )
    logger.info("FFmpeg %s completed successfully.", label)
