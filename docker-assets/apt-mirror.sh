#!/bin/bash -e
########################################################################################################################
##  File:  docker-assets/apt-mirror.sh
##  Desc:  Build-time only: point the Ubuntu APT sources to the Azure mirrors (same network as GitHub-hosted runners).
##  Usage: APT_MIRROR=azure apt-mirror.sh enable|restore  (no-op unless APT_MIRROR=azure)
########################################################################################################################

SOURCES="/etc/apt/sources.list.d/ubuntu.sources"
BACKUP="/var/tmp/ubuntu.sources.orig"

[[ "${APT_MIRROR:-}" == "azure" ]] || exit 0

case "${1:-}" in
    enable)
        cp -p "$SOURCES" "$BACKUP"
        sed -i -E \
            -e 's#//(archive|security)\.ubuntu\.com/#//azure.archive.ubuntu.com/#' \
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
