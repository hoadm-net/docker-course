#!/usr/bin/env bash
# Chapter 11 - operations: solutions
# Usage: bash ch11_operations/solutions.sh            (list functions)
#        bash ch11_operations/solutions.sh <function> [<function> ...]
set -euo pipefail
cd "$(dirname "$0")/.."        # always run from the repository root

ex_11_1() {
  # Log rotation per container (see daemon.json for the host-wide default).
  docker run -d --name api --log-opt max-size=1m --log-opt max-file=2 -p 8000:8000 vietmart-api:1.1
  sleep 2
  for _ in 1 2 3; do curl -s localhost:8000/healthz >/dev/null; done
  docker logs --tail 3 --timestamps api
  docker inspect api --format '{{.HostConfig.LogConfig}}'
  docker rm -f api
}

ex_11_2() {
  # Restart policy: a failing container is restarted up to 3 times, then left stopped.
  docker run -d --name flaky --restart on-failure:3 alpine:3 sh -c "echo starting; sleep 1; exit 1"
  sleep 15
  docker inspect flaky --format 'restarts={{.RestartCount}} status={{.State.Status}} exit={{.State.ExitCode}}'
  docker logs flaky
  docker rm -f flaky
}

ex_11_3() {
  docker run -d --name limited --memory 128m --cpus 0.5 vietmart-api:1.1
  sleep 2
  docker stats --no-stream --format 'table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.PIDs}}' limited
  docker rm -f limited
  # Exceeding the memory limit: the kernel kills the process, exit code 137.
  docker run --name hungry --memory 64m --memory-swap 64m vietmart-api:1.1 \
    python -c "x = bytearray(512 * 1024 * 1024)" || true
  docker inspect hungry --format 'OOMKilled={{.State.OOMKilled}} exit={{.State.ExitCode}}'
  docker rm hungry
}

ex_11_4() {
  # Debugging a container that exits immediately.
  docker run -d --name broken vietmart-api:1.1 gunicorn --bind 0.0.0.0:8000 wrong_module:app || true
  sleep 3
  docker ps -a --filter name=broken --format '{{.Names}}: {{.Status}}'
  docker logs broken 2>&1 | tail -n 5                     # 1. read the logs
  docker inspect broken --format 'exit={{.State.ExitCode}} cmd={{json .Config.Cmd}}'   # 2. inspect state
  docker run --rm --entrypoint sh vietmart-api:1.1 -c 'ls /app'        # 3. open the image with a shell
  docker rm broken
}

ex_11_5() {
  docker system df
  docker image prune -f              # dangling images only
  # docker system prune --volumes    # everything unused, including volumes: read the prompt carefully
}

# Dispatcher: run the functions named on the command line, or list them.
if [ $# -eq 0 ]; then declare -F | awk '{print $3}'; else for fn in "$@"; do echo "=== $fn ==="; "$fn"; done; fi
