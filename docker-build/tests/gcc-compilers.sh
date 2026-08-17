#!/bin/bash
set -euo pipefail

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

# Only versioned binaries (gcc-NN/g++-NN) are installed here - no unversioned
# `gcc`/`g++` alternative is set up by install-gcc-compilers.sh.
gxx=$(compgen -c 'g++-' | sort -V | tail -n1 || true)
gcc=$(compgen -c 'gcc-' | sort -V | tail -n1 || true)
[ -n "$gxx" ] && [ -n "$gcc" ] || { echo "no versioned gcc/g++ binary found"; exit 1; }

cat > "$WORKDIR/hello.c" <<'EOF'
#include <stdio.h>
int main(void) { printf("hello from %s\n", "gcc"); return 0; }
EOF
"$gcc" -Wall -Werror -o "$WORKDIR/hello_c" "$WORKDIR/hello.c"
[ "$("$WORKDIR/hello_c")" == "hello from gcc" ]

cat > "$WORKDIR/hello.cpp" <<'EOF'
#include <iostream>
#include <vector>
int main() {
    std::vector<int> v{1, 2, 3};
    for (int x : v) std::cout << x;
    std::cout << std::endl;
    return 0;
}
EOF
"$gxx" -Wall -Werror -o "$WORKDIR/hello_cpp" "$WORKDIR/hello.cpp"
[ "$("$WORKDIR/hello_cpp")" == "123" ]
