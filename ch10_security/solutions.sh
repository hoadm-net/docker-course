#!/usr/bin/env bash
# Chapter 10 - security: solutions
# Usage: bash ch10_security/solutions.sh            (list functions)
#        bash ch10_security/solutions.sh <function> [<function> ...]
set -euo pipefail
cd "$(dirname "$0")/.."        # always run from the repository root

ex_10_1() {
  # Either tool works; both list known CVEs per package.
  docker scout quickview vietmart-api:1.1 || echo "docker scout not installed"
  docker scout cves --only-severity critical,high vietmart-api:1.1 || true
  # trivy image --severity HIGH,CRITICAL vietmart-api:1.1
}

ex_10_2() {
  docker volume create vietmart-data
  docker run -d --name api-secure -p 127.0.0.1:8000:8000 \
    --read-only --tmpfs /tmp \
    --cap-drop ALL --security-opt no-new-privileges \
    --pids-limit 100 --memory 256m --cpus 0.5 \
    -v vietmart-data:/data \
    vietmart-api:1.1
  sleep 3
  curl -s localhost:8000/; echo
  docker exec api-secure sh -c 'touch /app/x' || echo "root filesystem is read-only"
  docker exec api-secure sh -c 'touch /tmp/x && touch /data/x && echo "tmpfs and volume are writable"'
  docker exec api-secure cat /proc/1/status | grep CapEff            # CapEff: 0000000000000000
  docker rm -f api-secure
}

ex_10_3() {
  cd ch10_security
  [ -f secrets/db_password.txt ] || cp secrets/db_password.txt.example secrets/db_password.txt
  chmod 644 secrets/db_password.txt
  docker compose up -d --build
  sleep 5
  curl -s localhost:8000/products; echo
  docker compose exec api sh -c 'env | grep -i password; ls -l /run/secrets/'    # only the *_FILE path is in the environment
  docker inspect "$(docker compose ps -q api)" --format '{{json .Config.Env}}' | tr ',' '\n' | grep -i password
  docker compose down --volumes
}

ex_10_4() {
  # Why secrets must not go into ENV or ARG: both are stored in the image metadata.
  printf 'FROM alpine:3\nARG TOKEN\nENV API_TOKEN=$TOKEN\n' | docker build -q -t leaky --build-arg TOKEN=s3cr3t -
  docker history --no-trunc leaky | grep -o "API_TOKEN=[^ ]*" | head -n 1
  docker inspect leaky --format '{{json .Config.Env}}'
  docker rmi leaky >/dev/null
}

cleanup() {
  docker rm -f api-secure 2>/dev/null || true
  docker volume rm vietmart-data 2>/dev/null || true
}

# Dispatcher: run the functions named on the command line, or list them.
if [ $# -eq 0 ]; then declare -F | awk '{print $3}'; else for fn in "$@"; do echo "=== $fn ==="; "$fn"; done; fi
