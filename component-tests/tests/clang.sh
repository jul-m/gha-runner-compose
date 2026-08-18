#!/bin/bash
set -euo pipefail

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

cat > "$WORKDIR/hello.c" <<'EOF'
#include <stdio.h>
int main(void) { printf("hello from clang\n"); return 0; }
EOF
clang -Wall -Werror -o "$WORKDIR/hello_c" "$WORKDIR/hello.c"
[ "$("$WORKDIR/hello_c")" == "hello from clang" ]

cat > "$WORKDIR/hello.cpp" <<'EOF'
#include <iostream>
int main() { std::cout << "hello from clang++" << std::endl; return 0; }
EOF
clang++ -Wall -Werror -o "$WORKDIR/hello_cpp" "$WORKDIR/hello.cpp"
[ "$("$WORKDIR/hello_cpp")" == "hello from clang++" ]

# malformed indentation clang-format must normalize to a single canonical form
cat > "$WORKDIR/messy.c" <<'EOF'
int main(void) {
        if (1) {
    return 0;
        }
}
EOF
formatted=$(clang-format -style=LLVM "$WORKDIR/messy.c")
[[ "$formatted" == *$'  if (1) {\n    return 0;\n  }'* ]]
