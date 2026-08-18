#!/bin/bash
set -euo pipefail

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

cd "$WORKDIR"
touch WORKSPACE

# `bazel info` exercises the bazelisk-resolved real binary beyond a bare
# version print - it needs a working server startup and workspace detection.
[ "$(bazel info workspace)" == "$WORKDIR" ]
bazel info release | grep -qE '[0-9]'

# `bazel` and `bazelisk` are two bin entrypoints onto the same npm-installed
# launcher - both must resolve to the identical underlying bazel binary.
[ "$(bazel version)" == "$(bazelisk version)" ]
