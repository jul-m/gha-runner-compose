#!/bin/bash -e
################################################################################
##  File:  docker-build/components/bicep.sh
##  Desc:  Override install-bicep.sh script to support arm64
################################################################################

source "$LOCAL_INSTALL/helpers.sh"

script="$BUILD_SCRIPTS/install-bicep.sh"

if [ ! -f "$script" ]; then
    fail "Missing upstream script for bicep: $script"
fi

if is_arm64; then
    log "Replace hardcoded x64 references with arm64 equivalents in install-bicep.sh upstream script."
    sed -i 's/bicep-linux-x64/bicep-linux-arm64/g' "$script"
    sh -c "$script" || fail "install-bicep.sh with arm64 overrides failed"
else
    sh -c "$script" || fail "install-bicep.sh failed (script not modified)"
fi

log "bicep installed"
