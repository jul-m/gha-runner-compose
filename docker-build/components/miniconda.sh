#!/bin/bash -e
################################################################################
##  File:  docker-build/components/miniconda.sh
##  Desc:  Override install-miniconda.sh to support arm64 installer
################################################################################

source "$LOCAL_INSTALL/helpers.sh"

script="$BUILD_SCRIPTS/install-miniconda.sh"

if [ ! -f "$script" ]; then
    fail "Missing upstream script for miniconda: $script"
fi

if is_arm64; then
    log "Patch upstream install-miniconda.sh to use the aarch64 installer"
    sed -i 's/Miniconda3-latest-Linux-x86_64.sh/Miniconda3-latest-Linux-aarch64.sh/g' "$script"
fi

sh -c "$script" || fail "install-miniconda.sh with arch override failed"

log "miniconda installed"

