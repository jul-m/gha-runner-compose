#!/bin/bash
################################################################################
##  File:  docker-build/components/docker.sh
##  Desc:  Override install-docker.sh script to support Docker
################################################################################

source "$LOCAL_INSTALL/helpers.sh"

script="$BUILD_SCRIPTS/install-docker.sh"
export DOCKERHUB_PULL_IMAGES="no"

if [ ! -f "$script" ]; then
    fail "Missing upstream script for docker: $script"
fi

# Comments systemd calls and other incompatible commands for container build context
sed -i 's/^cat <<EOF | sudo tee \/etc\/tmpfiles.d\/docker.conf/# cat <<EOF | sudo tee \/etc\/tmpfiles.d\/docker.conf/g' "$script"
sed -i 's/^L \/run\/docker.sock/# L \/run\/docker.sock/g' "$script"
sed -i '/^# L \/run\/docker.sock/ { n; s/^/# / }' "$script"
sed -i 's/^systemd-tmpfiles /# systemd-tmpfiles /g' "$script"
sed -i 's/^systemctl is-active/# systemctl is-active/g;s/^systemctl is-enabled/# systemctl is-enabled/g' "$script"

# Comments docker calls and tests (daemon not available in build context)
sed -i 's/^sleep 10/# sleep 10/g' "$script"
sed -i 's/^docker info/# docker info/g' "$script"

# Upstream also pre-pulls a set of images (Dependabot updater, gh-aw firewall/MCP server) on
# non-22.04 images, guarded by `if ! is_ubuntu22; then ... fi`. This requires a running daemon
# too, so comment out the whole block (not just the `docker pull` lines, to keep the script
# syntactically valid with an empty if-body).
sed -i '/^if ! is_ubuntu22; then$/,/^fi$/ s/^/# /' "$script"

# invoke_tests is wired up globally (see install-components.sh:ensure_invoke_tests), but the
# Docker Pester tests exercise a running daemon, which does not exist during `docker build`.
# Skip them deliberately here rather than let them fail.
sed -i 's/^invoke_tests/# invoke_tests/g' "$script"

sh -c "$script" || fail "docker install failed"

log "install-docker.sh successfully executed. Adding 'runner' user to 'docker' group."
usermod -aG docker runner

log "Docker installed"