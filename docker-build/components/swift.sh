#!/bin/bash -e
################################################################################
##  File:  docker-build/components/swift.sh
##  Desc:  Override install-swift.sh script to support arm64
################################################################################

source "$LOCAL_INSTALL/helpers.sh"

script="$BUILD_SCRIPTS/install-swift.sh"

if [ ! -f "$script" ]; then
    fail "Missing upstream script for swift: $script"
fi

if is_arm64; then
    log "Replace hardcoded references to support arm64 in install-swift.sh upstream script."
    sed -i 's/image_label="ubuntu$(lsb_release -rs)"/image_label="ubuntu$(lsb_release -rs)-aarch64"/g' "$script"

    log "Install APT dependencies for Swift on ARM64: libncurses6"
    apt-get install -y --no-install-recommends libncurses6

    sh -c "$script" || fail "install-swift.sh with arm64 overrides failed"
else
    sh -c "$script" || fail "install-swift.sh failed (script not modified)"
fi

log "swift installed"
