#!/bin/bash
set -euo pipefail

terraform version

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT
cd "$WORKDIR"

# no provider blocks - init/plan/apply resolve entirely offline
cat > main.tf <<'EOF'
variable "name" {
  type    = string
  default = "gha-runner-compose"
}

output "greeting" {
  value = "hello ${var.name}"
}
EOF

terraform init -input=false -no-color
terraform validate -no-color
terraform apply -input=false -auto-approve -no-color

[ "$(terraform output -raw greeting)" == "hello gha-runner-compose" ]
