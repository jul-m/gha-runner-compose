#!/bin/bash
set -euo pipefail

azcopy --version

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT
export AZCOPY_JOB_PLAN_LOCATION="$WORKDIR/plans"
export AZCOPY_LOG_LOCATION="$WORKDIR/logs"
mkdir -p "$AZCOPY_JOB_PLAN_LOCATION" "$AZCOPY_LOG_LOCATION"

# azcopy has no Local-Local entry in its FromTo table (confirmed against its
# own error output) - it's a cloud-transfer tool, so a real local-to-local
# copy isn't possible offline. Exercise the local job-history subsystem
# instead, which reads/writes AZCOPY_JOB_PLAN_LOCATION with no cloud endpoint.
azcopy jobs list
