#!/bin/bash -e
################################################################################
##  File:  docker-build/components/apt-common.sh
##  Desc:  Override install-apt-common.sh script to use correct package names
##         for ambiguous virtual packages
################################################################################

source "$LOCAL_INSTALL/helpers.sh"

script="$BUILD_SCRIPTS/install-apt-common.sh"

if [ ! -f "$script" ]; then
    fail "Missing upstream script for apt-common: $script"
fi

log "Replace 'netcat' with 'netcat-openbsd' in upstream script if present."
sed -i '/apt-get install --no-install-recommends $package/i if [ "$package" = "netcat" ]; then package="netcat-openbsd"; fi' "$script"

sh -c "$script" || fail "install-apt-common.sh failed"

log "apt-common installed"