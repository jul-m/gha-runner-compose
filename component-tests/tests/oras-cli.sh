#!/bin/bash
set -euo pipefail

oras version

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT
cd "$WORKDIR"

# full push/pull round trip against a local OCI image layout dir - no registry or network needed
echo "gha-runner-compose oras test" > hi.txt
oras push --oci-layout layout:v1 hi.txt

mkdir out
cd out
oras pull --oci-layout ../layout:v1
diff hi.txt ../hi.txt

oras manifest fetch --oci-layout ../layout:v1 | grep -q '"mediaType":"application/vnd.oci.image.manifest.v1+json"'
