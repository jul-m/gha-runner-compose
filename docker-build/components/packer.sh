#!/bin/bash -e
################################################################################
##  File:  docker-build/components/packer.sh
##  Desc:  Override install-packer.sh to select arm64 builds from HashiCorp
################################################################################

source "$LOCAL_INSTALL/helpers.sh"

script="$BUILD_SCRIPTS/install-packer.sh"

if [ ! -f "$script" ]; then
    fail "Missing upstream script for packer: $script"
fi

if is_arm64; then
    log "Patch packer installer to select arm64 build when on arm64"
    sed -i 's/.arch=="amd64"/.arch=="arm64"/g' "$script"
    sh -c "$script" || fail "install-packer.sh with arm64 overrides failed"
else
	sh -c "$script" || fail "install-packer.sh failed (script not modified)"
fi

log "packer installed"
