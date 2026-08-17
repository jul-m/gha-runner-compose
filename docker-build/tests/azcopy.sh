#!/bin/bash
set -euo pipefail

azcopy --version

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT
export AZCOPY_JOB_PLAN_LOCATION="$WORKDIR/plans"
export AZCOPY_LOG_LOCATION="$WORKDIR/logs"
mkdir -p "$AZCOPY_JOB_PLAN_LOCATION" "$AZCOPY_LOG_LOCATION"

src="$WORKDIR/src"
dst="$WORKDIR/dst"
mkdir -p "$src"
echo "test" > "$src/file.txt"

# local file-to-file copy - no service endpoint involved, exercises the real transfer engine
azcopy copy "$src/file.txt" "$dst/file.txt" --output-type text
[ -f "$dst/file.txt" ]
diff "$src/file.txt" "$dst/file.txt"

# jobs list reads the plan files just written above, purely local job history
azcopy jobs list | grep -q "JobId"
