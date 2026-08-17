#!/bin/bash
set -euo pipefail

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

# install-gfortran.sh installs the versionless `gfortran` package last, which
# registers the unversioned binary via update-alternatives - prefer it, but
# fall back to the newest versioned one if that ever changes.
gfc=$(command -v gfortran || compgen -c 'gfortran-' | sort -V | tail -n1 || true)
[ -n "$gfc" ] || { echo "no gfortran binary found"; exit 1; }

cat > "$WORKDIR/hello.f90" <<'EOF'
program hello
  integer :: i, total
  total = 0
  do i = 1, 5
    total = total + i
  end do
  print '(A,I0)', "sum=", total
end program hello
EOF

"$gfc" -Wall -Werror -o "$WORKDIR/hello" "$WORKDIR/hello.f90"
[ "$("$WORKDIR/hello")" == "sum=15" ]
