#!/usr/bin/env bash
# Chapter 2 - first containers: solutions
# Usage: bash ch02_first_containers/solutions.sh            (list functions)
#        bash ch02_first_containers/solutions.sh <function> [<function> ...]
set -euo pipefail
cd "$(dirname "$0")/.."        # always run from the repository root

ex_2_1() {
  docker version
  docker run hello-world
  docker ps -a --filter ancestor=hello-world
  docker rm $(docker ps -aq --filter ancestor=hello-world)
}

ex_2_2() {
  docker run -d --name web -p 8080:80 nginx:1.28-alpine
  sleep 2
  curl -s localhost:8080 | head -n 5
  docker logs web | tail -n 3
  # Change a file inside the running container (it lands in the container's writable layer).
  docker exec web sh -c 'echo "<h1>Hello VietMart</h1>" > /usr/share/nginx/html/index.html'
  curl -s localhost:8080
  # A new container starts again from the unchanged image: the edit is gone.
  docker rm -f web
  docker run -d --name web -p 8080:80 nginx:1.28-alpine
  sleep 2
  curl -s localhost:8080 | head -n 5
  docker rm -f web
}

ex_2_3() {
  # Run the app in a stock Python image, with the project bind-mounted. No Dockerfile yet.
  docker run -d --name vietmart-dev -p 8000:8000 \
    -v "$PWD/app-v1:/app" -w /app \
    python:3.13-slim sh -c "pip install -r requirements.txt && python src/app.py"
  sleep 15                                   # wait for pip install
  curl -s localhost:8000/
  curl -s localhost:8000/products
  curl -s localhost:8000/healthz
  docker rm -f vietmart-dev
}

# Dispatcher: run the functions named on the command line, or list them.
if [ $# -eq 0 ]; then declare -F | awk '{print $3}'; else for fn in "$@"; do echo "=== $fn ==="; "$fn"; done; fi
