#!/bin/bash -e
################################################################################
##  File:  docker-build/components/firefox.sh
##  Desc:  Override install-firefox.sh script to support arm64
################################################################################

source "$LOCAL_INSTALL/helpers.sh"

script="$BUILD_SCRIPTS/install-firefox.sh"

if [ ! -f "$script" ]; then
    fail "Missing upstream script for firefox: $script"
fi

if is_arm64; then
    log "Replace hardcoded linux64 references with linux-aarch64 equivalents in install-firefox.sh upstream script."
    sed -i 's/linux64\.tar\.gz/linux-aarch64.tar.gz/g' "$script"
    sh -c "$script" || fail "install-firefox.sh with arm64 overrides failed"
else
    sh -c "$script" || fail "install-firefox.sh failed (script not modified)"
fi

log "firefox installed"
