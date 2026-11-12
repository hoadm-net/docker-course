#!/usr/bin/env bash
# Chapter 8 - Docker Compose: solutions (run from anywhere)
# Usage: bash ch08_compose/solutions.sh            (list functions)
#        bash ch08_compose/solutions.sh <function> [<function> ...]
set -euo pipefail
cd "$(dirname "$0")/.."        # always run from the repository root

cd ch08_compose
[ -f .env ] || cp .env.example .env

ex_8_1() {
  docker compose up -d --build
  docker compose ps
  sleep 3
  curl -s localhost:8000/; echo
  curl -s localhost:8000/products; echo
}

ex_8_2() {
  # depends_on + healthcheck: watch the start order, then prove the data survives `down`.
  docker compose down
  docker compose up -d
  docker compose ps --format 'table {{.Service}}\t{{.Status}}'
  sleep 3
  curl -s localhost:8000/; echo
  docker compose down                 # containers and network removed, named volumes kept
  docker compose up -d
  sleep 3
  curl -s localhost:8000/; echo       # the visit counter continues
  docker volume ls --filter name=vietmart
}

ex_8_3() {
  docker compose -f compose.yaml -f compose.proxy.yaml up -d --build --scale api=3
  sleep 3
  for _ in 1 2 3 4 5 6; do curl -s localhost:8080/ ; echo; done     # "host" rotates between replicas
  docker compose -f compose.yaml -f compose.proxy.yaml ps
}

ex_8_4() {
  docker compose -f compose.yaml -f compose.dev.yaml --profile tools up -d
  echo "Adminer: http://localhost:8081  (server: db, user: vietmart, database: vietmart)"
  echo "Live reload: docker compose -f compose.yaml -f compose.dev.yaml watch"
}

cleanup() {
  docker compose -f compose.yaml -f compose.proxy.yaml -f compose.dev.yaml --profile tools down --volumes
}

# Dispatcher: run the functions named on the command line, or list them.
if [ $# -eq 0 ]; then declare -F | awk '{print $3}'; else for fn in "$@"; do echo "=== $fn ==="; "$fn"; done; fi
