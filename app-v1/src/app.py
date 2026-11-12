"""VietMart Catalog API - version 1 (single container, no external services)."""
import os
import socket
from pathlib import Path

from flask import Flask, jsonify

app = Flask(__name__)
app.json.ensure_ascii = False        # return UTF-8 instead of \u escapes

VERSION = os.environ.get("APP_VERSION", "dev")
DATA_DIR = Path(os.environ.get("DATA_DIR", "/tmp/vietmart"))

PRODUCTS = [
    {"id": 1, "name": "Headphones", "price": 450000},
    {"id": 2, "name": "Keyboard", "price": 890000},
    {"id": 3, "name": "Cà phê Buôn Ma Thuột", "price": 120000},
]


def increment_visits() -> int:
    """Count visits in a file under DATA_DIR (used to demonstrate volumes)."""
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    counter = DATA_DIR / "visits.txt"
    visits = int(counter.read_text()) + 1 if counter.exists() else 1
    counter.write_text(str(visits))
    return visits


@app.get("/")
def index():
    return jsonify(service="vietmart-catalog", version=VERSION,
                   host=socket.gethostname(), visits=increment_visits())


@app.get("/products")
def products():
    return jsonify(PRODUCTS)


@app.get("/healthz")
def healthz():
    return jsonify(status="ok")


if __name__ == "__main__":
    # 0.0.0.0, not 127.0.0.1: inside a container, localhost is the container itself.
    app.run(host="0.0.0.0", port=8000)
