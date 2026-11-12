#!/usr/bin/env bash
# Chapter 5 - image optimization: solutions
# Usage: bash ch05_image_optimization/solutions.sh            (list functions)
#        bash ch05_image_optimization/solutions.sh <function> [<function> ...]
set -euo pipefail
cd "$(dirname "$0")/.."        # always run from the repository root

ex_5_1() {
  docker build -t vietmart-api:1.1 --build-arg APP_VERSION=1.1 -f ch05_image_optimization/Dockerfile app-v1
  docker images vietmart-api
  docker history vietmart-api:1.1
}

ex_5_2() {
  docker run -d --name api -p 8000:8000 vietmart-api:1.1
  sleep 2
  docker exec api id                                        # uid=10001(appuser)
  docker exec api sh -c 'touch /app/hack.txt' || echo "cannot write to /app: not owned by appuser"
  docker exec api sh -c 'touch /data/ok.txt && echo "can write to /data"'
  docker rm -f api
}

ex_5_3() {
  docker run -d --name api --health-interval 2s vietmart-api:1.1
  for _ in 1 2 3 4 5; do docker inspect api --format '{{.State.Health.Status}}'; sleep 2; done
  # A container whose check always fails becomes "unhealthy" after the configured retries.
  docker run -d --name api-bad --health-cmd "exit 1" --health-interval 2s --health-retries 2 vietmart-api:1.1
  sleep 7
  docker ps --filter name=api --format '{{.Names}}: {{.Status}}'
  docker rm -f api api-bad
}

ex_5_4() {
  docker build -q -t vietmart-api:1.2 --build-arg APP_VERSION=1.2 -f ch05_image_optimization/Dockerfile app-v1
  docker inspect vietmart-api:1.2 --format '{{index .Config.Labels "org.opencontainers.image.version"}}'
  docker run --rm vietmart-api:1.2 env | grep APP_VERSION
}

ex_5_5() {
  # Optional: multi-platform build. Needs QEMU emulation (bundled with Docker Desktop) and
  # an image store that can hold multi-platform images (the containerd image store).
  docker buildx build --platform linux/amd64,linux/arm64 \
    -t vietmart-api:1.1-multi -f ch05_image_optimization/Dockerfile app-v1
  docker buildx imagetools inspect vietmart-api:1.1-multi || docker image inspect vietmart-api:1.1-multi --format '{{.Architecture}}'
}

# Dispatcher: run the functions named on the command line, or list them.
if [ $# -eq 0 ]; then declare -F | awk '{print $3}'; else for fn in "$@"; do echo "=== $fn ==="; "$fn"; done; fi
