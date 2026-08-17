#!/bin/bash
################################################################################
##  File:  docker-build/tests/apt-common.sh
##  Desc:  Custom coverage for the apt-common component. Upstream's Pester
##         "Apt" test only checks apt.cmd_packages/apt.vital_packages, never
##         apt.common_packages - so this samples across that list instead.
################################################################################

set -euo pipefail

dpkg -s libssl-dev >/dev/null
dpkg -s libicu-dev >/dev/null
dpkg -s fonts-noto-color-emoji >/dev/null

command -v gpg >/dev/null
command -v ip >/dev/null
command -v ssh >/dev/null
command -v tree >/dev/null

# python-is-python3 only provides a /usr/bin/python symlink to python3, no
# package of its own binary name - worth checking the symlink resolves.
command -v python >/dev/null
