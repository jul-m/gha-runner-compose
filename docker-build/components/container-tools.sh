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

# Comment out invoke_tests as Docker functions are not available during Docker image build
sed -i 's/invoke_tests "Tools" "Containers"/# invoke_tests "Tools" "Containers"  # Docker functions not available during Docker image build/g' "$script"

sh -c "$script" || fail "container-tools install failed"

log "container-tools installed"