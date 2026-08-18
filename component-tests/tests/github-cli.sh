#!/bin/bash
set -euo pipefail

gh --version
gh --help >/dev/null

tmp_home="$(mktemp -d)"
export HOME="$tmp_home"
trap 'rm -rf "$tmp_home"' EXIT

gh config set editor vim
[ "$(gh config get editor)" == "vim" ]

gh alias set test-alias 'pr list'
gh alias list | grep -qx 'test-alias: pr list'
gh alias delete test-alias

gh completion -s bash | grep -q '^__start_gh()'
