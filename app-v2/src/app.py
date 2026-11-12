"""VietMart Catalog API - version 2 (PostgreSQL for products, Redis for the visit counter)."""
import os
import socket

import psycopg
import redis
from flask import Flask, jsonify

app = Flask(__name__)
app.json.ensure_ascii = False

VERSION = os.environ.get("APP_VERSION", "dev")


def read_setting(name: str) -> str:
    """Read NAME from the environment, or from the file named by NAME_FILE (Docker secrets)."""
    file_path = os.environ.get(f"{name}_FILE")
    if file_path:
        with open(file_path, encoding="utf-8") as f:
            return f.read().strip()
    return os.environ[name]


def db_connect() -> psycopg.Connection:
    return psycopg.connect(
        host=os.environ.get("DB_HOST", "db"),
        dbname=os.environ.get("DB_NAME", "vietmart"),
        user=os.environ.get("DB_USER", "vietmart"),
        password=read_setting("DB_PASSWORD"),
        connect_timeout=3,
    )


cache = redis.Redis(host=os.environ.get("REDIS_HOST", "redis"), port=6379,
                    decode_responses=True, socket_connect_timeout=3)


@app.get("/")
def index():
    return jsonify(service="vietmart-catalog", version=VERSION,
                   host=socket.gethostname(), visits=cache.incr("visits"))


@app.get("/products")
def products():
    with db_connect() as conn:
        cur = conn.execute("SELECT id, name, price FROM products ORDER BY id")
        columns = [c.name for c in cur.description]
        return jsonify([dict(zip(columns, row)) for row in cur.fetchall()])


@app.get("/healthz")
def healthz():
    """Healthy only when both dependencies answer."""
    with db_connect() as conn:
        conn.execute("SELECT 1")
    cache.ping()
    return jsonify(status="ok")


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000)
