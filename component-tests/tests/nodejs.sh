#!/bin/bash
set -euo pipefail

node --version >/dev/null

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

cat > "$WORKDIR/script.js" <<'EOF'
console.log(2 + 3);
EOF
[ "$(node "$WORKDIR/script.js")" == "5" ] || { echo "node execution failed"; exit 1; }

npm --version >/dev/null

cd "$WORKDIR"
npm init -y >/dev/null
[ -f "$WORKDIR/package.json" ]
[ -n "$(node -p "require('./package.json').name")" ]

# compile+run a real .ts file through the globally installed tsc, beyond upstream's `tsc --version` check
cat > "$WORKDIR/hello.ts" <<'EOF'
const greet = (name: string): string => `hello, ${name}`;
console.log(greet("world"));
EOF
tsc --target ES2020 --outDir "$WORKDIR/dist" "$WORKDIR/hello.ts"
[ "$(node "$WORKDIR/dist/hello.js")" == "hello, world" ]
