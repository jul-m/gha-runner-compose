#!/bin/bash
set -euo pipefail

zstd --version

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

original="$WORKDIR/original.txt"
head -c 100000 /dev/urandom | base64 > "$original"

zstd -q "$original" -o "$WORKDIR/original.txt.zst"
[ -f "$WORKDIR/original.txt.zst" ]

unzstd -q "$WORKDIR/original.txt.zst" -o "$WORKDIR/decompressed.txt"
diff "$original" "$WORKDIR/decompressed.txt"

# unzstd is a symlink to zstd, not its own binary - verify the alias resolves and works
zstdcat "$WORKDIR/original.txt.zst" | diff "$original" -
