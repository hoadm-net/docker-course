#!/usr/bin/env bash
# Chapter 7 - networking: solutions
# Usage: bash ch07_networking/solutions.sh            (list functions)
#        bash ch07_networking/solutions.sh <function> [<function> ...]
set -euo pipefail
cd "$(dirname "$0")/.."        # always run from the repository root

ex_7_1() {
  echo "--- default bridge: no DNS between containers"
  docker run -d --name api vietmart-api:1.1; sleep 2
  docker run --rm alpine:3 wget -qO- -T 3 http://api:8000/healthz || echo "name 'api' does not resolve on the default bridge"
  ip=$(docker inspect api --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')
  docker run --rm alpine:3 wget -qO- -T 3 "http://$ip:8000/healthz"; echo "  <- works by IP"
  docker rm -f api

  echo "--- user-defined bridge: embedded DNS resolves container names"
  docker network create vietmart-net
  docker run -d --name api --network vietmart-net vietmart-api:1.1; sleep 2
  docker run --rm --network vietmart-net alpine:3 wget -qO- -T 3 http://api:8000/healthz; echo
}

ex_7_2() {
  # The api container from 7.1 publishes no port: unreachable from the host, reachable inside the network.
  curl -s -m 2 localhost:8000/healthz || echo "not reachable from the host: no published port"
  docker rm -f api
  # Publish on the loopback interface only.
  docker run -d --name api --network vietmart-net -p 127.0.0.1:8000:8000 vietmart-api:1.1; sleep 2
  docker port api
  curl -s localhost:8000/healthz; echo
}

ex_7_3() {
  docker network inspect vietmart-net --format '{{range .Containers}}{{.Name}} {{.IPv4Address}}{{"\n"}}{{end}}'
  docker run -d --name api2 --network vietmart-net --network-alias catalog vietmart-api:1.1; sleep 2
  docker run --rm --network vietmart-net alpine:3 wget -qO- -T 3 http://catalog:8000/healthz; echo
  docker run --rm --network vietmart-net alpine:3 cat /etc/resolv.conf     # nameserver 127.0.0.11
}

ex_7_4() {
  docker run --rm --network none alpine:3 sh -c 'ls /sys/class/net; wget -qO- -T 2 http://example.com || echo "no network at all"'
}

cleanup() {
  docker rm -f api api2 2>/dev/null || true
  docker network rm vietmart-net 2>/dev/null || true
}

# Dispatcher: run the functions named on the command line, or list them.
if [ $# -eq 0 ]; then declare -F | awk '{print $3}'; else for fn in "$@"; do echo "=== $fn ==="; "$fn"; done; fi
