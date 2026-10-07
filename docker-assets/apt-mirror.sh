#!/bin/bash -e
########################################################################################################################
##  File:  docker-assets/apt-mirror.sh
##  Desc:  Build-time only: point the Ubuntu APT sources to mirrors that answer reliably from GitHub-hosted runners
##         (archive.ubuntu.com times out there): kernel.org CDN on amd64, Azure ports mirror on arm64.
##  Usage: APT_MIRROR=ci apt-mirror.sh enable|restore  (no-op unless APT_MIRROR=ci)
########################################################################################################################

SOURCES="/etc/apt/sources.list.d/ubuntu.sources"
BACKUP="/var/tmp/ubuntu.sources.orig"

[[ "${APT_MIRROR:-}" == "ci" ]] || exit 0

case "${1:-}" in
    enable)
        cp -p "$SOURCES" "$BACKUP"
        sed -i -E \
            -e 's#//(archive|security)\.ubuntu\.com/#//mirrors.edge.kernel.org/#' \
            -e 's#//ports\.ubuntu\.com/#//azure.ports.ubuntu.com/#' "$SOURCES"
        ;;
    restore)
        [[ -f "$BACKUP" ]] && mv -f "$BACKUP" "$SOURCES"
        ;;
    *)
        echo "Usage: $0 enable|restore" >&2
        exit 2
        ;;
esac
