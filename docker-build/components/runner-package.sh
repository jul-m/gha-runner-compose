#!/bin/bash -e
################################################################################
##  File:  docker-build/components/runner-package.sh
##  Desc:  Download and cache the actions/runner release archive so
##         entrypoint.sh can extract it at container startup instead of
##         fetching it over the network on every run.
##
##  Project-maintained: upstream removed its equivalent install-runner-package.sh
##  (commit d0d1862c, Nov 2025) as "unused" for GitHub-hosted runners, but this
##  cache is load-bearing here, so the logic now lives directly in this script
##  rather than patching a script that no longer exists upstream.
################################################################################

source "$LOCAL_INSTALL/helpers.sh"
# Local scripts run as a separate `bash` process (see process_component()), so
# the helpers sourced by install-components.sh's main shell aren't inherited -
# unlike upstream install-*.sh scripts, which source this themselves.
source "$HELPER_SCRIPTS/install.sh"

if is_arm64; then
    arch_suffix="arm64"
else
    arch_suffix="x64"
fi

url_filter='test("actions-runner-linux-'"${arch_suffix}"'-[0-9]+\\.[0-9]{3}\\.[0-9]+\\.tar\\.gz$")'
download_url=$(resolve_github_release_asset_url "actions/runner" "$url_filter" "latest")
archive_name="${download_url##*/}"
archive_path=$(download_with_retry "$download_url")

mkdir -p /opt/runner-cache
mv "$archive_path" "/opt/runner-cache/$archive_name"

log "Runner package installed"
