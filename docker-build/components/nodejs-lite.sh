#!/bin/bash -e
################################################################################
##  File:  docker-build/components/nodejs-lite.sh
##  Desc:  Install Node.js LTS without modules (based on install-nodejs.sh)
################################################################################

# Source the helpers for use with the script
source $HELPER_SCRIPTS/install.sh
source "$LOCAL_INSTALL/helpers.sh"

# Install default Node.js
default_version=$(get_toolset_value '.node.default')
curl -fsSL https://raw.githubusercontent.com/tj/n/master/bin/n -o ~/n
bash ~/n $default_version

# fix global modules installation as regular user
# related issue https://github.com/actions/runner-images/issues/3727
sudo chmod -R 777 /usr/local/lib/node_modules 
sudo chmod -R 777 /usr/local/bin

rm -rf ~/n

# Comment out the Node.js installation lines in the upstream script to prevent re-installation
sed -i 's|^curl -fsSL https://raw.githubusercontent.com/tj/n/master/bin/n -o ~/n|# &|' "$BUILD_SCRIPTS/install-nodejs.sh"
sed -i 's|^bash ~/n |# &|' "$BUILD_SCRIPTS/install-nodejs.sh"

# Test - Check if version matches expected
installed_version=$(node --version | sed 's/^v//') || fail "Failed to get Node.js version"
if [[ "$installed_version" != "$default_version"* ]]; then
    echo "Node.js version mismatch: expected $default_version, got $installed_version"
    exit 1
fi
echo "Node.js version check passed: $installed_version"
