# ── Stage 1: Build dependencies ───────────────────────────────────────────────
FROM python:3.12-slim AS builder

WORKDIR /app

# Install build tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ── Stage 2: Runtime image with FFmpeg ────────────────────────────────────────
FROM python:3.12-slim

WORKDIR /app

# Install FFmpeg
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# Copy installed Python packages from builder
COPY --from=builder /install /usr/local

# Copy application source
COPY . .

# Create temp directory for media processing
RUN mkdir -p /tmp/yohpal_worker

# Non-root user for security
RUN useradd -m -u 1000 worker && chown -R worker:worker /app /tmp/yohpal_worker
USER worker

# Cloud Run listens on port 8080
EXPOSE 8080

ENV PORT=8080
ENV PYTHONUNBUFFERED=1
ENV TEMP_DIR=/tmp/yohpal_worker

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080", "--workers", "1"]
