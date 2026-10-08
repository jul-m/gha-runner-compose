#!/bin/bash
set -euo pipefail

CONDA_PREFIX_DIR=/usr/share/miniconda
[ -x "$CONDA_PREFIX_DIR/bin/conda" ]

conda --version

# confirms conda actually resolves its own install prefix, not just that the binary runs
conda info | grep -q "$CONDA_PREFIX_DIR"

pkg_count=$(conda list | grep -vc '^#')
[ "$pkg_count" -gt 0 ] || { echo "conda base environment has no packages"; exit 1; }
