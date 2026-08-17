#!/bin/bash
set -euo pipefail

# avoid the background component-manager update check, which reaches out to
# the network and would otherwise stall/fail in this offline container
export CLOUDSDK_COMPONENT_MANAGER_DISABLE_UPDATE_CHECK=1
export CLOUDSDK_CORE_DISABLE_PROMPTS=1

gcloud --version

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT
export CLOUDSDK_CONFIG="$WORKDIR/config"

gcloud config set project test-project-offline --quiet
[ "$(gcloud config get-value project)" == "test-project-offline" ]
gcloud config configurations list --format="value(is_active)" | grep -qx "True"

gcloud config unset project --quiet
[ -z "$(gcloud config get-value project 2>/dev/null)" ]

# fresh config dir has no credentials store yet - confirms auth list parses locally without a network call
[ -z "$(gcloud auth list --format='value(account)')" ]
