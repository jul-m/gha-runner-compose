#!/bin/bash -e
################################################################################
##  File:  docker-build/components/cmake.sh
##  Desc:  Override install-cmake.sh script to support arm64
################################################################################

source "$LOCAL_INSTALL/helpers.sh"

script="$BUILD_SCRIPTS/install-cmake.sh"

if [ ! -f "$script" ]; then
    fail "Missing upstream script for cmake: $script"
fi

if is_arm64; then
    log "Replace hardcoded x86_64 references with aarch64 equivalents in install-cmake.sh upstream script."
    # "L" of Linux missing in upstream script
    sed -i 's/inux-x86_64\.sh/inux-aarch64.sh/g' "$script"
    sh -c "$script" || fail "install-cmake.sh with aarch64 overrides failed"
else
    sh -c "$script" || fail "install-cmake.sh failed (script not modified)"
fi

log "cmake installed"
