#!/bin/bash -e
################################################################################
##  File:  docker-build/components/yq.sh
##  Desc:  Override install-yq.sh script to support arm64
################################################################################

source "$LOCAL_INSTALL/helpers.sh"

script="$BUILD_SCRIPTS/install-yq.sh"

if [ ! -f "$script" ]; then
    fail "Missing upstream script for yq: $script"
fi

if is_arm64; then
    log "Adapting upstream yq script for arm64"
    sed -i 's/yq_linux_amd64/yq_linux_arm64/g' "$script"
    sh -c "$script" || fail "install-yq.sh with arm64 overrides failed"
else
    sh -c "$script" || fail "install-yq.sh failed (script not modified)"
fi
