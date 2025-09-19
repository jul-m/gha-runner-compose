#!/usr/bin/env bash
# helpers.sh - utilitaires shell pour l'image runner
# Fournit une fonction cleanup pour purger /tmp (avec exceptions) et /var/log

IFS=$'\n\t'


# Logging and fail
log(){
    echo "[$(basename "$0")] $*" >&2;
}

warn(){
    echo "[$(basename "$0")][WARN] $*" >&2;
}

fail(){
    echo "[$(basename "$0")][ERROR] $*" >&2; exit 1;
}


# Architecture detection
export ARCH_RAW=$(uname -m)

case "$ARCH_RAW" in
    x86_64|amd64) export ARCH_SHORT="x64" ;;
    aarch64|arm64) export ARCH_SHORT="arm64" ;;
    *) fail "Arch non supportée $ARCH_RAW" ;;
esac

is_arm64() {
    [[ "$ARCH_SHORT" == "arm64" ]]
}

is_x64() {
    [[ "$ARCH_SHORT" == "x64" ]]
}
