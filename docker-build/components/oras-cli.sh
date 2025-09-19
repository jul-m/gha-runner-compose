#!/bin/bash -e
################################################################################
##  File:  docker-build/components/oras-cli.sh
##  Desc:  Override install-oras-cli.sh to select linux_arm64 asset and checksum on arm64
################################################################################

source "$LOCAL_INSTALL/helpers.sh"

script="$BUILD_SCRIPTS/install-oras-cli.sh"

if [ ! -f "$script" ]; then
    fail "Missing upstream script for oras-cli: $script"
fi

if is_arm64; then
    log "Patch ORAS installer to use linux_arm64 asset and checksum"
    sed -i 's/linux_amd64.tar.gz/linux_arm64.tar.gz/g' "$script"
    sed -i 's/linux_amd64/linux_arm64/g' "$script"
    sh -c "$script" || fail "install-oras-cli.sh with arm64 overrides failed"
else
	sh -c "$script" || fail "install-oras-cli.sh failed (script not modified)"
fi

log "oras-cli installed"
