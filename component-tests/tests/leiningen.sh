#!/bin/bash
set -euo pipefail

[ -n "${LEIN_JAR:-}" ]
[ -s "$LEIN_JAR" ]

# `lein version`/`lein help` go through the launcher's self-install check even
# though $LEIN_JAR already exists, which fails here: the jar was written by
# the build-time root user and self-installs/ isn't writable by the runtime
# runner user. The standalone jar bundles its own dependencies and has its
# own version entry point, so run it directly and skip the launcher entirely.
java -jar "$LEIN_JAR" version | grep -q "Leiningen"
