#!/bin/bash -e
################################################################################
##  File:  docker-build/components/bazel.sh
##  Desc:  Override install-bazel.sh script to fix a broken version pipeline
################################################################################

source "$LOCAL_INSTALL/helpers.sh"

script="$BUILD_SCRIPTS/install-bazel.sh"

if [ ! -f "$script" ]; then
    fail "Missing upstream script for bazel: $script"
fi

# Upstream extracts BAZEL_VERSION from `bazel --version`, but that flag form
# prints a short "bazel X.Y.Z" line with no "Build label:" text - only the
# `bazel version` subcommand (used a few lines above) prints that. The grep
# then matches nothing, and under this project's `bash -eo pipefail` wrapper
# (see install-components.sh) that empty match aborts the whole script.
sed -i 's/bazel --version | grep "Build label:"/bazel version | grep "Build label:"/' "$script"

sh -c "$script" || fail "bazel install failed"

log "bazel installed"
