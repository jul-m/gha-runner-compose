#!/bin/bash
set -euo pipefail

heroku --version

# heroku plugins/commands both work fully offline (oclif-based, local command tree)
heroku plugins

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

heroku commands --json > "$WORKDIR/commands.json"
grep -q '"id": "apps"' "$WORKDIR/commands.json"
grep -q '"id": "addons"' "$WORKDIR/commands.json"

# autocomplete script generation is local, no auth/network required
heroku autocomplete:script bash | grep -q "heroku autocomplete setup"
