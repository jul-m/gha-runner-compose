#!/bin/bash -e
################################################################################
##  File:  docker-build/components/azcopy.sh
##  Desc:  Override install-azcopy.sh script to support arm64
################################################################################

source "$LOCAL_INSTALL/helpers.sh"

script="$BUILD_SCRIPTS/install-azcopy.sh"

if [ ! -f "$script" ]; then
    fail "Missing upstream script for azcopy: $script"
fi

if is_arm64; then
    log "Replace azcopy download URL with ARM64 equivalent in install-azcopy.sh upstream script."
    sed -i 's|https://aka.ms/downloadazcopy-v10-linux|https://aka.ms/downloadazcopy-v10-linux-arm64|g' "$script"
    sh -c "$script" || fail "install-azcopy.sh with arm64 overrides failed"
else
    sh -c "$script" || fail "install-azcopy.sh failed (script not modified)"
fi

log "azcopy installed"
