#!/bin/bash -e
################################################################################
##  File:  docker-build/components/container-tools.sh
##  Desc:  Install container tools: podman, buildah and skopeo with Docker build adaptations
################################################################################

source "$LOCAL_INSTALL/helpers.sh"

script="$BUILD_SCRIPTS/install-container-tools.sh"

if [ ! -f "$script" ]; then
    fail "Missing upstream script for container-tools: $script"
fi

# invoke_tests is wired up globally (see install-components.sh:ensure_invoke_tests), but this
# component's Pester tests exercise podman/buildah/skopeo against a running daemon, which does
# not exist during `docker build`. Skip them deliberately here rather than let them fail.
sed -i 's/invoke_tests "Tools" "Containers"/# invoke_tests "Tools" "Containers"/g' "$script"

sh -c "$script" || fail "container-tools install failed"

log "container-tools installed"