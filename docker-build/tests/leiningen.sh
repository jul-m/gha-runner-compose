#!/bin/bash
set -euo pipefail

[ -n "${LEIN_JAR:-}" ]
[ -f "$LEIN_JAR" ]

lein version

# exercises the self-installed standalone jar beyond a version print, without
# touching the network for dependency resolution (which `lein new`/build would need)
lein help >/dev/null
