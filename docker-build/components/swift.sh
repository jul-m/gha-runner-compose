#!/bin/bash -e
################################################################################
##  File:  docker-build/components/swift.sh
##  Desc:  Install Swift, adding the arm64-only apt dependency the upstream
##         install-swift.sh doesn't handle itself
################################################################################

source "$LOCAL_INSTALL/helpers.sh"

script="$BUILD_SCRIPTS/install-swift.sh"

if [ ! -f "$script" ]; then
    fail "Missing upstream script for swift: $script"
fi

if is_arm64; then
    log "Install APT dependencies for Swift on ARM64: libncurses6"
    apt-get install -y --no-install-recommends libncurses6
fi

sh -c "$script" || fail "install-swift.sh failed"

log "swift installed"
