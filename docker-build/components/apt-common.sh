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

sh -c "$script" || fail "install-apt-common.sh failed"

log "apt-common installed"