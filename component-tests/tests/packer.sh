#!/bin/bash
set -euo pipefail

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

# the `null` source is built into packer core (no plugin download) and does
# nothing on build - safe to actually run, not just validate, with no network.
cat > "$WORKDIR/null.pkr.hcl" <<'EOF'
source "null" "test" {
  communicator = "none"
}

build {
  sources = ["source.null.test"]
}
EOF

packer validate "$WORKDIR/null.pkr.hcl"

output=$(packer build "$WORKDIR/null.pkr.hcl")
[[ "$output" == *"Build 'null.test' finished"* ]]
