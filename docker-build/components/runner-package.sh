#!/bin/bash -e
################################################################################
##  File:  docker-build/components/runner-package.sh
##  Desc:  Override for install-runner-package.sh to support ARM64 architecture
################################################################################

source "$LOCAL_INSTALL/helpers.sh"

script="$BUILD_SCRIPTS/install-runner-package.sh"

if [ ! -f "$script" ]; then
    fail "Missing upstream script for runner-package: $script"
fi

if is_arm64; then
    log "Adapting runner package download for ARM64 architecture"
    # Replace x64 with arm64 in the download URL pattern
    sed -i 's/linux-x64/linux-arm64/g' "$script"
fi

# Execute the adapted upstream script
sh -c "$script" || fail "Runner package install failed"

log "Runner package installed"