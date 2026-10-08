#!/bin/bash
set -euo pipefail

# install-pypy.sh has no invoke_tests call, so this is the only test PyPy gets.
# Each toolset version (see toolset.json) lands under its own hostedtoolcache
# folder, and the interpreter binary is always named pypy3 regardless of the
# Python version it targets (major_version is derived from the package name).
shopt -s nullglob
pypy_bins=(/opt/hostedtoolcache/PyPy/*/x64/bin/pypy3)
[ ${#pypy_bins[@]} -gt 0 ] || { echo "no PyPy install found under /opt/hostedtoolcache/PyPy"; exit 1; }

for pypy in "${pypy_bins[@]}"; do
    "$pypy" -c "
import hashlib, json, sys

assert hasattr(sys, 'pypy_version_info'), 'not running under the real PyPy interpreter'

payload = json.dumps({'value': 6 * 7})
assert json.loads(payload)['value'] == 42

digest = hashlib.sha256(b'test').hexdigest()
assert digest == '9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08'
"

    # install-pypy.sh symlinks python3/python to pypy3 in the same bin dir
    # (required for the UsePythonVersion Azure DevOps task) - confirm they work too.
    bin_dir=$(dirname "$pypy")
    "$bin_dir/python3" -c "import sys; assert hasattr(sys, 'pypy_version_info')"
done
