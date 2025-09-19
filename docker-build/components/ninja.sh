#!/bin/bash -e
################################################################################
##  File:  docker-build/components/ninja.sh
##  Desc:  Override install-ninja.sh to support arm64 (use ninja-linux-aarch64.zip)
################################################################################

source "$LOCAL_INSTALL/helpers.sh"

script="$BUILD_SCRIPTS/install-ninja.sh"

if [ ! -f "$script" ]; then
	fail "Missing upstream script for ninja: $script"
fi

if is_arm64; then
	log "Replace ninja-linux.zip with ninja-linux-aarch64.zip in upstream install-ninja.sh for arm64"
	sed -i 's/ninja-linux.zip/ninja-linux-aarch64.zip/g' "$script"
	sh -c "$script" || fail "install-ninja.sh with arm64 overrides failed"
else
	sh -c "$script" || fail "install-ninja.sh failed (script not modified)"
fi

log "ninja installed"

