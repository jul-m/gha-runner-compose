#!/bin/bash
set -euo pipefail

dotnet --version

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

cd "$WORKDIR"
# The console template's implicit restore resolves entirely from the SDK's
# bundled NuGetFallbackFolder, so this compiles and runs with no network access.
dotnet new console -o app >/dev/null
cd app
dotnet build -c Release >/dev/null
[ "$(dotnet run -c Release --no-build)" == "Hello, World!" ]
