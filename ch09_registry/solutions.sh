#!/usr/bin/env bash
# Chapter 9 - registries: solutions
# Usage: bash ch09_registry/solutions.sh            (list functions)
#        bash ch09_registry/solutions.sh <function> [<function> ...]
set -euo pipefail
cd "$(dirname "$0")/.."        # always run from the repository root

ex_9_1() {
  # A private registry on localhost: no account needed.
  docker run -d --name registry -p 5000:5000 registry:3
  docker tag vietmart-api:1.1 localhost:5000/vietmart-api:1.1
  docker push localhost:5000/vietmart-api:1.1
  curl -s localhost:5000/v2/_catalog; echo
  curl -s localhost:5000/v2/vietmart-api/tags/list; echo
}

ex_9_2() {
  # One image, several tags: exact version, minor line, and the git commit.
  sha=$(git rev-parse --short HEAD 2>/dev/null || echo "abc1234")
  for tag in 1.1.0 1.1 "sha-$sha"; do
    docker tag vietmart-api:1.1 "localhost:5000/vietmart-api:$tag"
    docker push -q "localhost:5000/vietmart-api:$tag"
  done
  curl -s localhost:5000/v2/vietmart-api/tags/list; echo
}

ex_9_3() {
  digest=$(docker inspect localhost:5000/vietmart-api:1.1 --format '{{index .RepoDigests 0}}')
  echo "immutable reference: $digest"
  docker rmi localhost:5000/vietmart-api:1.1
  docker pull "$digest"               # pull by digest: guaranteed to be the same bytes
}

ex_9_4() {
  docker save -o vietmart-api-1.1.tar vietmart-api:1.1
  ls -lh vietmart-api-1.1.tar
  docker rmi vietmart-api:1.1
  docker load -i vietmart-api-1.1.tar
  rm vietmart-api-1.1.tar
}

cleanup() {
  docker rm -f registry 2>/dev/null || true
}

# Dispatcher: run the functions named on the command line, or list them.
if [ $# -eq 0 ]; then declare -F | awk '{print $3}'; else for fn in "$@"; do echo "=== $fn ==="; "$fn"; done; fi
