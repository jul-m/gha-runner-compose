#!/bin/bash
set -euo pipefail

# No cluster/API server is reachable here, so only client-side checks: version
# output and kubectl's local, offline manifest validation (--dry-run=client).

kubectl version --client
helm version
kind version
kustomize version

# On arm64, docker-build/components/kubernetes-tools.sh replaces the real
# minikube binary with a lightweight shim (only 'version --short' is
# meaningful there) - this call is safe against both.
minikube version --short

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

cat > "$WORKDIR/pod.yaml" <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
  labels:
    app: test
spec:
  containers:
    - name: test-container
      image: busybox:latest
      command: ["sleep", "3600"]
EOF

# --validate defaults to fetching the OpenAPI schema from a live cluster even
# under --dry-run=client (there's no cluster reachable here) - turn it off.
kubectl apply --dry-run=client --validate=false -f "$WORKDIR/pod.yaml"
