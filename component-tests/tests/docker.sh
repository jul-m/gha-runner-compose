#!/bin/bash
set -euo pipefail

# No daemon is reachable at test time (bare `docker run`, no --privileged, no
# socket mount - see .github/actions/build-test-runner-image/action.yml), same
# reason docker-build/components/docker.sh comments out upstream's own
# `invoke_tests` call. Only client-side/offline checks below - never `docker
# info`, `docker ps`, `docker run`, etc.

docker --version

# CLI plugins installed straight from GitHub releases (install-docker.sh)
docker buildx version
docker compose version

# amazon-ecr-credential-helper binary
command -v docker-credential-ecr-login

# docker-build/components/docker.sh adds 'runner' to the 'docker' group after
# install so it can reach the socket once the daemon is actually up elsewhere.
getent group docker >/dev/null
id -nG runner | grep -qw docker
