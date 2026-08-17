#!/bin/bash
set -euo pipefail

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT
cd "$WORKDIR"

# The upstream Pester test only checks that cmake can *generate* a build.ninja
# file, never that ninja actually builds anything - cover the real execution
# and dependency-tracking path here.
echo "one" > a.txt
cat > build.ninja <<'EOF'
rule copy
  command = cp $in $out
build b.txt: copy a.txt
build c.txt: copy b.txt
EOF

ninja c.txt
[ "$(cat c.txt)" == "one" ]

# touching the root input must trigger a rebuild of the whole chain
sleep 1
echo "two" > a.txt
ninja c.txt
[ "$(cat c.txt)" == "two" ]

# with no inputs changed, ninja must report nothing to do
output=$(ninja c.txt)
[[ "$output" == *"no work to do"* ]]
