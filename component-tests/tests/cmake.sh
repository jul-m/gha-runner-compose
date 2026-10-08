#!/bin/bash
set -euo pipefail

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

# NONE-language project: exercises cmake's configure/generate/build pipeline
# without pulling in a specific compiler toolchain.
cat > "$WORKDIR/CMakeLists.txt" <<'EOF'
cmake_minimum_required(VERSION 3.10)
project(CmakeTest NONE)
add_custom_command(
    OUTPUT "${CMAKE_BINARY_DIR}/output.txt"
    COMMAND ${CMAKE_COMMAND} -E echo "built by cmake" > "${CMAKE_BINARY_DIR}/output.txt"
)
add_custom_target(build_output ALL DEPENDS "${CMAKE_BINARY_DIR}/output.txt")
EOF

# ninja is installed alongside cmake in this component tier - use it as the
# generator so this test doesn't also depend on a system `make` binary.
cmake -S "$WORKDIR" -B "$WORKDIR/build" -G Ninja >/dev/null
cmake --build "$WORKDIR/build" >/dev/null

[ "$(cat "$WORKDIR/build/output.txt")" == "built by cmake" ]
