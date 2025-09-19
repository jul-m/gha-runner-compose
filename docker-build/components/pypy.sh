#!/bin/bash -e
################################################################################
##  File:  docker-build/components/pypy.sh
##  Desc:  Override install-pypy.sh to select arm64 builds from PyPy
################################################################################

source "$LOCAL_INSTALL/helpers.sh"

script="$BUILD_SCRIPTS/install-pypy.sh"

if [ ! -f "$script" ]; then
    fail "Missing upstream script for pypy: $script"
fi

if is_arm64; then
    log "Patch pypy installer to select arm64 build when on arm64"
    sed -i 's/"x64"/"aarch64"/g' "$script"
    sh -c "$script" || fail "install-pypy.sh with arm64 overrides failed"
else
	sh -c "$script" || fail "install-pypy.sh failed (script not modified)"
fi

log "pypy installed"
