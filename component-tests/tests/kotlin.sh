#!/bin/bash
set -euo pipefail

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

cat > "$WORKDIR/hello.kt" <<'EOF'
fun main() {
    println("hello from kotlin")
}
EOF

cd "$WORKDIR"
kotlinc hello.kt -include-runtime -d hello.jar
[ -f hello.jar ]
[ "$(java -jar hello.jar)" == "hello from kotlin" ]

# `kotlin` only runs .kts as a script directly - a plain .kt needs the jar above
cat > "$WORKDIR/hello.kts" <<'EOF'
println("hello from kotlin")
EOF
[ "$(kotlin hello.kts)" == "hello from kotlin" ]
