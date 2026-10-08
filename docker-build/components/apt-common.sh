#!/bin/bash -e
################################################################################
##  File:  docker-build/components/apt-common.sh
##  Desc:  Override install-apt-common.sh script to use correct package names
##         for ambiguous virtual packages
################################################################################

source "$LOCAL_INSTALL/helpers.sh"

script="$BUILD_SCRIPTS/install-apt-common.sh"

if [ ! -f "$script" ]; then
    fail "Missing upstream script for apt-common: $script"
fi

log "Replace 'netcat' with 'netcat-openbsd' in upstream script if present."
sed -i '/apt-get install --no-install-recommends $package/i if [ "$package" = "netcat" ]; then package="netcat-openbsd"; fi' "$script"

# Fetch every package in one apt run: the per-package installs below then reuse the downloaded archives
# instead of paying a new mirror connection (often stalling for 30-60 s) for each package.
download_cmd='apt-get install --download-only --no-install-recommends -y $(printf "%s\n" $common_packages $cmd_packages | sed "s/^netcat$/netcat-openbsd/")'
DOWNLOAD_CMD="$download_cmd" awk '/^for package in/ {print ENVIRON["DOWNLOAD_CMD"]} {print}' "$script" > "$script.new"
cat "$script.new" > "$script" && rm -f "$script.new"

# Upstream's Apt tests assert the VM's apt-mirrors.txt failover list, which this container build does not create.
apt_tests="$TEST_SCRIPTS/Apt.Tests.ps1"
if [ -f "$apt_tests" ]; then
    sed -i '/It "Apt sources resolve through the mirror list"/s/-Skip:\$usesPortsArchive/-Skip/' "$apt_tests"
    sed -i '/It "Mirror list entries have unique priorities"/s/ {$/ -Skip {/' "$apt_tests"
fi

sh -c "$script" || fail "install-apt-common.sh failed"

log "apt-common installed"