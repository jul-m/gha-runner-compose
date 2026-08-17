#!/bin/bash
set -euo pipefail

# podman/buildah/skopeo are daemonless CLIs, but exercising real storage/network
# ops here would depend on kernel features not guaranteed inside this test
# container - stick to version checks and the config files install-container-tools.sh
# writes on disk.

podman --version
buildah --version
skopeo --version

# install_podman_static's crun runtime-path fix (actions/runner-images#14473)
[ -f /etc/containers/containers.conf.d/00-fix-runtime.conf ]
grep -q 'crun = \["/usr/local/bin/crun"\]' /etc/containers/containers.conf.d/00-fix-runtime.conf
command -v crun

# unqualified-search-registries written by install-container-tools.sh
grep -q 'docker.io' /etc/containers/registries.conf
grep -q 'quay.io' /etc/containers/registries.conf

# netavark/iptables firewall driver fix (actions/runner-images#14230)
[ -f /etc/containers/containers.conf.d/99-fix-firewall.conf ]
grep -q 'firewall_driver = "iptables"' /etc/containers/containers.conf.d/99-fix-firewall.conf
