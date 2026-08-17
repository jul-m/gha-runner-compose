#!/bin/bash
set -euo pipefail

# nvm is a shell function sourced from nvm.sh, not a binary on PATH - command -v won't find it.
# install-nvm.sh sets NVM_DIR to this path before running nvm's own installer, so this is
# where nvm.sh actually ends up regardless of the runtime user's HOME/.bash_profile wiring.
NVM_DIR="/etc/skel/.nvm"
NVM_SCRIPT="$NVM_DIR/nvm.sh"
[ -s "$NVM_SCRIPT" ] || { echo "nvm.sh not found at $NVM_SCRIPT"; exit 1; }

bash <<EOF
set +u
export NVM_DIR="$NVM_DIR"
. "$NVM_SCRIPT"
set -u

type nvm >/dev/null 2>&1 || { echo "nvm is not defined as a shell function after sourcing"; exit 1; }
nvm --version >/dev/null

# install-nvm.sh runs 'nvm alias default system' after its Pester test, so only this
# custom script actually exercises that the alias/default resolution was set up correctly
nvm current | grep -q "system"
nvm ls | grep -q "system"
EOF
