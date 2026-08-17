#!/bin/bash
set -euo pipefail

yq --version

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

cat > "$WORKDIR/sample.yaml" <<'EOF'
name: gha-runner-compose
components:
  - git
  - yq
nested:
  value: 42
EOF

[ "$(yq '.name' "$WORKDIR/sample.yaml")" == "gha-runner-compose" ]
[ "$(yq '.nested.value' "$WORKDIR/sample.yaml")" == "42" ]
[ "$(yq '.components[1]' "$WORKDIR/sample.yaml")" == "yq" ]

# round-trip through JSON to confirm the built-in format conversion works
[ "$(yq -o=json '.nested.value' "$WORKDIR/sample.yaml")" == "42" ]
