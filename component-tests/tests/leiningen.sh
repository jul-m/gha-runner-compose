#!/bin/bash
set -euo pipefail

[ -n "${LEIN_JAR:-}" ]
[ -r "$LEIN_JAR" ]

# Go through the real `lein` launcher, not a bare `java -jar` - the
# standalone jar's command dispatch expects the environment/args the
# launcher sets up.
lein version | grep -q "Leiningen"
lein help >/dev/null
