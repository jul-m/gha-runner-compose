#!/bin/bash
################################################################################
##  File:  docker-build/components/docker.sh
##  Desc:  Override install-docker.sh script to support Docker and arm64
################################################################################

source "$LOCAL_INSTALL/helpers.sh"

script="$BUILD_SCRIPTS/install-docker.sh"
export DOCKERHUB_PULL_IMAGES="no"

if [ ! -f "$script" ]; then
    fail "Missing upstream script for docker: $script"
fi

if is_arm64; then
    log "Adapting upstream docker script for arm64"
    sed -i 's/amd64/arm64/g' "$script"
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
sed -i 's/^invoke_tests/# invoke_tests/g' "$script"

sh -c "$script" || fail "docker install failed"

log "install-docker.sh successfully executed. Adding 'runner' user to 'docker' group."
usermod -aG docker runner

log "Docker installed"