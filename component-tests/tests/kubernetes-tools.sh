#!/bin/bash
set -euo pipefail

# No cluster/API server is reachable here. kubectl's dry-run=client still
# needs a live server for RESTMapper discovery regardless of --validate or
# apply vs create (confirmed: kubernetes/kubectl#991) - offline manifest
# validation isn't possible with kubectl alone, so client-side checks only.

kubectl version --client
helm version
kind version
kustomize version

# On arm64, docker-build/components/kubernetes-tools.sh replaces the real
# minikube binary with a lightweight shim (only 'version --short' is
# meaningful there) - this call is safe against both.
minikube version --short
