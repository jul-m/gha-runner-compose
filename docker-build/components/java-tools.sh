#!/bin/bash -e
################################################################################
##  File:  docker-build/components/java-tools.sh
##  Desc:  Override install-java-tools.sh script to support arm64
################################################################################

source "$LOCAL_INSTALL/helpers.sh"

script="$BUILD_SCRIPTS/install-java-tools.sh"

if [ ! -f "$script" ]; then
    fail "Missing upstream script for java-tools: $script"
fi

if is_arm64; then
    log "Replace hardcoded amd64 references with arm64 equivalents in install-java-tools.sh upstream script."
    sed -i 's/-amd64/-arm64/g' "$script"
    sed -i 's/\/x64/\/arm64/g' "$script"
    sh -c "$script" || fail "install-java-tools.sh with arm64 overrides failed"
else
    sh -c "$script" || fail "install-java-tools.sh failed (script not modified)"
fi

log "java-tools installed"
