#!/bin/bash
set -euo pipefail

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT
export AZURE_CONFIG_DIR="$WORKDIR/.azure"

az devops -h >/dev/null

# az devops configure --defaults only writes AZURE_CONFIG_DIR/config, no API call
az devops configure --defaults organization=https://dev.azure.com/test-org project=test-project
az devops configure --list | grep -q "test-org"
az devops configure --list | grep -q "test-project"
