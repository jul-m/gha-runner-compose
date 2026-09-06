#!/bin/bash
set -euo pipefail

# podman/buildah/skopeo are daemonless CLIs, but exercising real storage/network
# ops here would depend on kernel features not guaranteed inside this test
# container - stick to version checks and the config files install-container-tools.sh
# writes on disk.

podman --version
buildah --version
skopeo --version

# unqualified-search-registries written by install-container-tools.sh
grep -q 'docker.io' /etc/containers/registries.conf
grep -q 'quay.io' /etc/containers/registries.conf

# netavark/iptables firewall driver fix (actions/runner-images#14230) only applies
# on Ubuntu 26.04 upstream; this image is built on 24.04, where it's never written.
