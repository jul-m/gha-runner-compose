#!/bin/bash
set -euo pipefail

# use the fixed install path directly rather than $VCPKG_INSTALLATION_ROOT -
# that variable is only exported into /etc/environment at build time and
# isn't sourced by a plain non-login test shell.
VCPKG_ROOT=/usr/local/share/vcpkg

[ -d "$VCPKG_ROOT/ports" ]
[ "$(find "$VCPKG_ROOT/ports" -mindepth 1 -maxdepth 1 | wc -l)" -gt 100 ]

# `search` scans the locally cloned ports catalog, no network required
vcpkg search zlib | grep -q "^zlib "
