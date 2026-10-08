#!/bin/bash
set -euo pipefail

bicep --version

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

# Azure resource type schemas are bundled in the bicep binary, so build/lint work offline
cat > "$WORKDIR/main.bicep" <<'EOF'
param location string = 'westeurope'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: 'ghartesta'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageAccount'
}

output storageAccountId string = storageAccount.id
EOF

bicep lint "$WORKDIR/main.bicep"
bicep build "$WORKDIR/main.bicep" --outfile "$WORKDIR/main.json"

[ -f "$WORKDIR/main.json" ]
grep -q '"Microsoft.Storage/storageAccounts"' "$WORKDIR/main.json"
