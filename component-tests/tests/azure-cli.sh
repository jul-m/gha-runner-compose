#!/bin/bash
set -euo pipefail

az version

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT
export AZURE_CONFIG_DIR="$WORKDIR/.azure"

# az config only reads/writes AZURE_CONFIG_DIR/config locally, no network involved
az config set defaults.location=eastus core.output=table
[ "$(az config get defaults.location --query value -o tsv)" == "eastus" ]
grep -q "location = eastus" "$AZURE_CONFIG_DIR/config"
