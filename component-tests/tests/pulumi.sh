#!/bin/bash
set -euo pipefail

pulumi version

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT
mkdir -p "$WORKDIR/state" "$WORKDIR/proj"

# local file backend avoids any call to the pulumi.com managed backend
export PULUMI_BACKEND_URL="file://$WORKDIR/state"
export PULUMI_CONFIG_PASSPHRASE=""

pulumi about

cd "$WORKDIR/proj"
cat > Pulumi.yaml <<'EOF'
name: gha-runner-compose-test
runtime: yaml
description: offline component test project
EOF

pulumi stack init test-stack --non-interactive
pulumi stack ls --json | grep -q '"name": "test-stack"'

pulumi config set testkey testvalue
[ "$(pulumi config get testkey)" == "testvalue" ]

pulumi stack rm test-stack --yes
