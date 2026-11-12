#!/usr/bin/env bash
# Chapter 13 - capstone: bring the stack up and check the acceptance criteria
# Usage: bash ch13_capstone/verify.sh            (list functions)
#        bash ch13_capstone/verify.sh <function> [<function> ...]
set -euo pipefail
cd "$(dirname "$0")/.."        # always run from the repository root

cd ch13_capstone
[ -f .env ] || cp .env.example .env
[ -f secrets/db_password.txt ] || cp secrets/db_password.txt.example secrets/db_password.txt
chmod 644 secrets/db_password.txt

up() {
  docker compose up -d --build --scale api=2
  docker compose ps --format 'table {{.Service}}\t{{.Status}}'
}

check() {
  echo "1. API answers through the proxy, replicas rotate:"
  for _ in 1 2 3 4; do curl -s localhost:8080/; echo; done
  echo "2. Products come from PostgreSQL:"
  curl -s localhost:8080/products; echo
  echo "3. API runs as non-root with a read-only root filesystem:"
  docker compose exec api id
  docker compose exec api sh -c 'touch /app/x' || echo "read-only: ok"
  echo "4. The database is not reachable from the host:"
  docker compose port db 5432 || echo "no published port: ok"
  echo "5. Data survives a full restart:"
  before=$(curl -s localhost:8080/ | grep -o '"visits":[0-9]*')
  docker compose down && docker compose up -d --scale api=2 && sleep 15
  echo "before: $before, after: $(curl -s localhost:8080/ | grep -o '"visits":[0-9]*')"
}

down() {
  docker compose down --volumes
}

# Dispatcher: run the functions named on the command line, or list them.
if [ $# -eq 0 ]; then declare -F | awk '{print $3}'; else for fn in "$@"; do echo "=== $fn ==="; "$fn"; done; fi
