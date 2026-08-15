#!/bin/bash -e
################################################################################
##  File:  docker-build/components/container-tools.sh
##  Desc:  Install container tools: podman, buildah and skopeo with Docker build adaptations
################################################################################

source "$LOCAL_INSTALL/helpers.sh"

script="$BUILD_SCRIPTS/install-container-tools.sh"

if [ ! -f "$script" ]; then
    fail "Missing upstream script for container-tools: $script"
fi

# invoke_tests is wired up globally (see install-components.sh:ensure_invoke_tests), but this
# component's Pester tests exercise podman/buildah/skopeo against a running daemon, which does
# not exist during `docker build`. Skip them deliberately here rather than let them fail.
sed -i 's/invoke_tests "Tools" "Containers"/# invoke_tests "Tools" "Containers"/g' "$script"

# apparmor_parser loads the podman profile into the live kernel LSM, which is
# meaningful for a packer-built VM image that boots with systemd/apparmor.service
# later. It's a no-op here either way: a `docker build` RUN step can't persist
# host-kernel state into the final image, and the built runner image never boots
# systemd to load /etc/apparmor.d/podman at runtime. The binary providing it also
# isn't installed on this minimal image, so skip the call rather than let it fail.
sed -i 's/apparmor_parser -r -W \/etc\/apparmor.d\/podman/: # apparmor_parser skipped (docker build has no kernel LSM to load into)/g' "$script"

sh -c "$script" || fail "container-tools install failed"

log "container-tools installed"