#!/bin/bash
set -euo pipefail

command -v sam

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT
export AWS_CONFIG_FILE="$WORKDIR/config"
export AWS_SHARED_CREDENTIALS_FILE="$WORKDIR/credentials"

# configure set/get only write/read the local profile files, no API call
aws configure set region eu-west-1 --profile test
aws configure set aws_access_key_id AKIDtest --profile test
aws configure set aws_secret_access_key SECRETtest --profile test
[ "$(aws configure get region --profile test)" == "eu-west-1" ]
aws configure list --profile test | grep -q "eu-west-1"

cat > "$WORKDIR/template.yaml" <<'EOF'
AWSTemplateFormatVersion: '2010-09-09'
Transform: AWS::Serverless-2016-10-31
Resources:
  TestFunction:
    Type: AWS::Serverless::Function
    Properties:
      Handler: index.handler
      Runtime: python3.12
      CodeUri: .
EOF

# --lint runs cfn-lint's rules and resource schemas bundled in the sam binary,
# unlike plain `sam validate` which calls the CloudFormation ValidateTemplate API
sam validate --template "$WORKDIR/template.yaml" --lint
