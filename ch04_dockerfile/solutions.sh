#!/usr/bin/env bash
# Chapter 4 - Dockerfile: solutions
# Usage: bash ch04_dockerfile/solutions.sh            (list functions)
#        bash ch04_dockerfile/solutions.sh <function> [<function> ...]
set -euo pipefail
cd "$(dirname "$0")/.."        # always run from the repository root

ex_4_1() {
  docker build -t vietmart-api:1.0 -f ch04_dockerfile/Dockerfile app-v1
  docker run -d --name api -p 8000:8000 vietmart-api:1.0
  sleep 3
  curl -s localhost:8000/; curl -s localhost:8000/products; curl -s localhost:8000/healthz
  docker rm -f api
}

ex_4_2() {
  # Dockerfile.bad-cache uses `COPY . .`, so everything in the context can end up in the image.
  # Put 20 MB of junk in a folder that .dockerignore excludes, then build with and without the file.
  mkdir -p app-v1/.venv && dd if=/dev/urandom of=app-v1/.venv/junk.bin bs=1M count=20 status=none
  trap 'rm -rf app-v1/.venv; [ -f /tmp/dockerignore.bak ] && mv /tmp/dockerignore.bak app-v1/.dockerignore' RETURN
  echo "--- with .dockerignore"
  docker build --progress=plain -t ctx-test -f ch04_dockerfile/Dockerfile.bad-cache app-v1 2>&1 | grep "transferring context" | tail -n 1
  docker run --rm ctx-test sh -c 'ls -a /app'
  mv app-v1/.dockerignore /tmp/dockerignore.bak
  echo "--- without .dockerignore"
  docker build --progress=plain -t ctx-test -f ch04_dockerfile/Dockerfile.bad-cache app-v1 2>&1 | grep "transferring context" | tail -n 1
  docker run --rm ctx-test sh -c 'ls -a /app'      # .venv (and any .env file) is now inside the image
  docker rmi ctx-test >/dev/null
}

ex_4_3() {
  cp app-v1/src/app.py /tmp/app.py.bak
  trap 'cp /tmp/app.py.bak app-v1/src/app.py' RETURN
  for file in Dockerfile Dockerfile.bad-cache; do
    docker build -q -t cache-test -f "ch04_dockerfile/$file" app-v1 >/dev/null     # warm the cache
    echo "# cache experiment $(date +%s%N)" >> app-v1/src/app.py                    # change the source only
    if docker build --progress=plain -t cache-test -f "ch04_dockerfile/$file" app-v1 2>&1 \
         | grep -A1 "RUN pip install" | grep -q CACHED; then
      echo "$file: pip install layer CACHED"
    else
      echo "$file: pip install layer RE-RUN"
    fi
  done
  docker rmi cache-test >/dev/null
}

ex_4_4() {
  docker build -q -t cmd-demo -f ch04_dockerfile/Dockerfile.cmd ch04_dockerfile
  docker build -q -t entrypoint-demo -f ch04_dockerfile/Dockerfile.entrypoint ch04_dockerfile
  docker run --rm cmd-demo                          # hello from CMD
  docker run --rm cmd-demo ls /                     # arguments replace the whole CMD
  docker run --rm entrypoint-demo                   # hello from the default CMD
  docker run --rm entrypoint-demo VietMart          # hello VietMart: arguments replace only CMD
  docker run --rm --entrypoint ls entrypoint-demo / # the entrypoint itself can still be overridden
  docker rmi cmd-demo entrypoint-demo >/dev/null
}

ex_4_5() {
  docker run -d --name api -p 8000:8000 -e APP_VERSION=9.9 vietmart-api:1.0
  sleep 3
  curl -s localhost:8000/                 # "version":"9.9" - runtime -e overrides the image's ENV
  docker exec api env | grep APP_VERSION
  docker rm -f api
}

# Dispatcher: run the functions named on the command line, or list them.
if [ $# -eq 0 ]; then declare -F | awk '{print $3}'; else for fn in "$@"; do echo "=== $fn ==="; "$fn"; done; fi
