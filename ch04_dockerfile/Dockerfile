# Chapter 4 - first working Dockerfile for VietMart Catalog (app-v1).
# Build:  docker build -t vietmart-api:1.0 -f ch04_dockerfile/Dockerfile app-v1
FROM python:3.13-slim

WORKDIR /app

# Dependencies first: this layer is rebuilt only when requirements.txt changes.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Source code last: it changes most often.
COPY src/ .

ENV APP_VERSION=1.0 \
    DATA_DIR=/data
EXPOSE 8000

# Exec form: gunicorn becomes PID 1 and receives SIGTERM directly.
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--access-logfile", "-", "app:app"]
