#!/bin/bash
set -euo pipefail

command -v git-ftp

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

cd "$WORKDIR"
git init -q
git config user.email "test@example.com"
git config user.name "Test User"
echo "test" > file.txt
git add file.txt
git commit -q -m "test commit"
[ "$(git log --oneline | wc -l)" -eq 1 ] || { echo "commit history mismatch"; exit 1; }
[ "$(git rev-parse --is-inside-work-tree)" == "true" ]

# actions/checkout relies on this global exemption (CVE-2022-24765 fix)
git config --get-all safe.directory | grep -qx '\*'

for host in github.com ssh.dev.azure.com; do
    ssh-keygen -F "$host" -f /etc/ssh/ssh_known_hosts >/dev/null
done
