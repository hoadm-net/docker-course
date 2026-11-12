# Current best Dockerfile for app-v1 (identical to ch05_image_optimization/Dockerfile).
# Build:  docker build -t vietmart-api:1.1 --build-arg APP_VERSION=1.1 app-v1

# ---------- Stage 1: build the virtual environment ----------
FROM python:3.13-slim AS builder
WORKDIR /app
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
COPY requirements.txt .
# Cache mount: pip's download cache survives between builds but never lands in a layer.
RUN --mount=type=cache,target=/root/.cache/pip pip install -r requirements.txt

# ---------- Stage 2: runtime image ----------
FROM python:3.13-slim AS runtime

ARG APP_VERSION=dev
LABEL org.opencontainers.image.title="vietmart-api" \
      org.opencontainers.image.version="${APP_VERSION}"

ENV APP_VERSION=${APP_VERSION} \
    DATA_DIR=/data \
    PATH="/opt/venv/bin:$PATH" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# Unprivileged user with a fixed UID, and a data directory it owns.
RUN useradd --create-home --uid 10001 appuser \
    && mkdir /data \
    && chown appuser:appuser /data

WORKDIR /app
COPY --from=builder /opt/venv /opt/venv
COPY src/ .

USER appuser
EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/healthz', timeout=2)"

# --no-control-socket: gunicorn would otherwise write a socket under $HOME,
# which fails on a read-only root filesystem (chapter 10).
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--access-logfile", "-", "--no-control-socket", "app:app"]
