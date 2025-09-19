#!/bin/bash -e
################################################################################
##  File:  docker-build/components/github-cli.sh
##  Desc:  Override install-github-cli.sh script to support arm64
################################################################################

source "$LOCAL_INSTALL/helpers.sh"

script="$BUILD_SCRIPTS/install-github-cli.sh"

if [ ! -f "$script" ]; then
    fail "Missing upstream script for github-cli: $script"
fi

if is_arm64; then
    log "Replace hardcoded amd64 references with arm64 equivalents in install-github-cli.sh upstream script."
    sed -i 's/amd64/arm64/g' "$script"
    sh -c "$script" || fail "install-github-cli.sh with arm64 overrides failed"
else
    sh -c "$script" || fail "install-github-cli.sh failed (script not modified)"
fi

log "github-cli installed"
