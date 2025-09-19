#!/bin/bash -e
################################################################################
##  File:  docker-build/components/aws-tools.sh
##  Desc:  Override install-aws-tools.sh script to support arm64
################################################################################

source "$LOCAL_INSTALL/helpers.sh"

script="$BUILD_SCRIPTS/install-aws-tools.sh"

if [ ! -f "$script" ]; then
    fail "Missing upstream script for aws-tools: $script"
fi

if is_arm64; then
    log "Replace hardcoded x86_64 references with arm64 equivalents in install-aws-tools.sh upstream script."
    sed -i 's/awscli-exe-linux-x86_64.zip/awscli-exe-linux-aarch64.zip/g' "$script"
    sed -i 's/aws-sam-cli-linux-x86_64.zip/aws-sam-cli-linux-arm64.zip/g' "$script"
    sed -i 's/ubuntu_64bit/ubuntu_arm64/g' "$script"
    sh -c "$script" || fail "install-aws-tools.sh with arm64 overrides failed"
else
    sh -c "$script" || fail "install-aws-tools.sh failed (script not modified)"
fi

log "aws-tools installed"