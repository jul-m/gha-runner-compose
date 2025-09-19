#!/bin/bash -e
################################################################################
##  File:  docker-build/components/julia.sh
##  Desc:  Override install-julia.sh script to support arm64
################################################################################

source "$LOCAL_INSTALL/helpers.sh"

script="$BUILD_SCRIPTS/install-julia.sh"

if [ ! -f "$script" ]; then
    fail "Missing upstream script for julia: $script"
fi

if is_arm64; then
    log "Adapting install-julia.sh for arm64: replace x86_64 artifacts with aarch64 equivalents."
    sed -i 's/x86_64-linux-gnu/aarch64-linux-gnu/g' "$script"
    sed -i 's/linux-x86_64.tar.gz/linux-aarch64.tar.gz/g' "$script"
    sed -i 's/x86_64/aarch64/g' "$script"
    sh -c "$script" || fail "install-julia.sh with arm64 overrides failed"
else
    sh -c "$script" || fail "install-julia.sh failed (script not modified)"
fi

log "julia installed"
