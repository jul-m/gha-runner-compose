#!/bin/bash
set -euo pipefail

git lfs version

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

cd "$WORKDIR"
git init -q repo
cd repo
git config user.email "test@example.com"
git config user.name "test"

git lfs install --local
grep -q "filter \"lfs\"" .git/config

git lfs track "*.bin"
[ -f .gitattributes ]
grep -q "filter=lfs" .gitattributes

echo "dummy content" > file.bin
git add .gitattributes file.bin
git commit -q -m "add lfs file"

git lfs ls-files | grep -q "file.bin"
