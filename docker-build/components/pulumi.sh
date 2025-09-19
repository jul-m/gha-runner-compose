#!/bin/bash -e
################################################################################
##  File:  docker-build/components/pulumi.sh
##  Desc:  Override install-pulumi.sh to select arm64 artifacts on arm64
################################################################################

source "$LOCAL_INSTALL/helpers.sh"

script="$BUILD_SCRIPTS/install-pulumi.sh"

if [ ! -f "$script" ]; then
    fail "Missing upstream script for pulumi: $script"
fi

if is_arm64; then
    log "Patch Pulumi installer to select linux-arm64 artifact and checksum on arm64"
    sed -i 's/linux-x64/linux-arm64/g' "$script"
    sed -i 's/-x64//g' "$script"
    sh -c "$script" || fail "install-pulumi.sh with arm64 overrides failed"
else
	sh -c "$script" || fail "install-pulumi.sh failed (script not modified)"
fi

log "pulumi installed"
