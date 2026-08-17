#!/bin/bash
set -euo pipefail

# --client skips any attempt to reach an API server
oc version --client

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT
export KUBECONFIG="$WORKDIR/kubeconfig"

oc config set-cluster test-cluster --server=https://api.example.invalid:6443 --insecure-skip-tls-verify=true
oc config set-credentials test-user --token=fake-offline-token
oc config set-context test-context --cluster=test-cluster --user=test-user --namespace=test-ns
oc config use-context test-context

[ "$(oc config current-context)" == "test-context" ]
[ "$(oc config view -o jsonpath='{.clusters[0].name}')" == "test-cluster" ]
[ "$(oc config view -o jsonpath='{.contexts[0].context.namespace}')" == "test-ns" ]

oc completion bash | grep -q "__oc_debug"
