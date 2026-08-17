#!/bin/bash
set -euo pipefail

# /usr/bin/sbt is a symlink into the versioned install dir - resolve it for real, not just `command -v`
sbt_real=$(readlink -f "$(command -v sbt)")
[ -x "$sbt_real" ]

# `sbt --version` only reads the launcher jar (no project init, no dependency
# resolution), so it stays network-free unlike `sbt sbtVersion` or a real build
version_output=$(sbt --version)
echo "$version_output"
[[ "$version_output" =~ [0-9]+\.[0-9]+\.[0-9]+ ]]
