#!/usr/bin/env bash
# Chapter 3 - images and containers: solutions
# Usage: bash ch03_images_containers/solutions.sh            (list functions)
#        bash ch03_images_containers/solutions.sh <function> [<function> ...]
set -euo pipefail
cd "$(dirname "$0")/.."        # always run from the repository root

ex_3_1() {
  for tag in 3.13 3.13-slim 3.13-alpine; do docker pull "python:$tag"; done
  docker images python
  docker history python:3.13-slim
}

ex_3_2() {
  docker run -d --name scratchpad alpine:3 sleep 3600
  docker exec scratchpad sh -c 'echo "remember me" > /note.txt'
  docker stop -t 1 scratchpad            # sleep as PID 1 ignores SIGTERM, so shorten the grace period
  docker start scratchpad
  docker exec scratchpad cat /note.txt   # still there: stop/start keeps the writable layer
  docker diff scratchpad                 # A /note.txt
  docker rm -f scratchpad
  docker run -d --name scratchpad alpine:3 sleep 3600
  docker exec scratchpad cat /note.txt || echo "file is gone: a new container gets a fresh writable layer"
  docker rm -f scratchpad
}

ex_3_3() {
  docker run -d --name web nginx:1.28-alpine
  docker inspect web --format 'IP:       {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'
  docker inspect web --format 'Status:   {{.State.Status}}'
  docker inspect web --format 'Started:  {{.State.StartedAt}}'
  docker inspect web --format 'Command:  {{json .Config.Entrypoint}} {{json .Config.Cmd}}'
  docker rm -f web
}

ex_3_4() {
  docker run -d --name short alpine:3 sh -c "echo start; sleep 5; echo end"
  docker ps -a --filter name=short --format '{{.Names}}: {{.Status}}'
  sleep 7
  docker ps -a --filter name=short --format '{{.Names}}: {{.Status}}'
  docker logs short
  docker inspect short --format 'exit code: {{.State.ExitCode}}'
  docker rm short
}

# Dispatcher: run the functions named on the command line, or list them.
if [ $# -eq 0 ]; then declare -F | awk '{print $3}'; else for fn in "$@"; do echo "=== $fn ==="; "$fn"; done; fi
