#!/bin/bash
set -euo pipefail

aliyun version

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT
export HOME="$WORKDIR"

# configure set/get only ever touch ~/.aliyun/config.json - no network call
aliyun configure set --profile test --mode AK --region cn-hangzhou --access-key-id AKIDtest --access-key-secret secrettest
[ -f "$WORKDIR/.aliyun/config.json" ]

aliyun configure get region --profile test | grep -q "cn-hangzhou"
aliyun configure list | grep -q "test"
