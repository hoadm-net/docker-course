#!/usr/bin/env bash
# Chapter 6 - storage: solutions
# Usage: bash ch06_storage/solutions.sh            (list functions)
#        bash ch06_storage/solutions.sh <function> [<function> ...]
set -euo pipefail
cd "$(dirname "$0")/.."        # always run from the repository root

hit() { for _ in 1 2 3; do curl -s localhost:8000/ ; echo; done; }

ex_6_1() {
  echo "--- without a volume: the counter dies with the container"
  docker run -d --name api -p 8000:8000 vietmart-api:1.1; sleep 2; hit
  docker rm -f api
  docker run -d --name api -p 8000:8000 vietmart-api:1.1; sleep 2; curl -s localhost:8000/; echo
  docker rm -f api

  echo "--- with a named volume: the counter survives"
  docker volume create vietmart-data
  docker run -d --name api -p 8000:8000 -v vietmart-data:/data vietmart-api:1.1; sleep 2; hit
  docker rm -f api
  docker run -d --name api -p 8000:8000 -v vietmart-data:/data vietmart-api:1.1; sleep 2; curl -s localhost:8000/; echo
  docker rm -f api
}

ex_6_2() {
  # Bind-mount the source and run Flask's reloader: edits on the host apply immediately.
  docker run -d --name api-dev -p 8000:8000 -v "$PWD/app-v1/src:/app" \
    vietmart-api:1.1 flask --app app run --host 0.0.0.0 --port 8000 --debug
  sleep 3
  curl -s localhost:8000/products
  echo "Now edit app-v1/src/app.py, call the endpoint again, then: docker rm -f api-dev"
}

ex_6_3() {
  mkdir -p backup
  docker run --rm -v vietmart-data:/data:ro -v "$PWD/backup:/backup" \
    alpine:3 tar czf /backup/vietmart-data.tgz -C /data .
  ls -l backup/
  docker volume create vietmart-restore
  docker run --rm -v vietmart-restore:/data -v "$PWD/backup:/backup:ro" \
    alpine:3 tar xzf /backup/vietmart-data.tgz -C /data
  docker run --rm -v vietmart-restore:/data alpine:3 cat /data/visits.txt; echo
}

ex_6_4() {
  docker run --rm -v "$PWD/app-v1/src:/src:ro" alpine:3 sh -c 'touch /src/x' || echo "read-only bind mount: write refused"
  docker run --rm --tmpfs /scratch alpine:3 sh -c 'echo hi > /scratch/f && df /scratch | tail -n 1'
}

cleanup() {
  docker rm -f api api-dev 2>/dev/null || true
  docker volume rm vietmart-data vietmart-restore 2>/dev/null || true
  rm -rf backup
}

# Dispatcher: run the functions named on the command line, or list them.
if [ $# -eq 0 ]; then declare -F | awk '{print $3}'; else for fn in "$@"; do echo "=== $fn ==="; "$fn"; done; fi
