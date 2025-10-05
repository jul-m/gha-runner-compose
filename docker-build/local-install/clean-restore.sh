#!/bin/bash -e
########################################################################################################################
##  File:  docker-build/local-install/clean-restore.sh
##  Desc:  Script to clean /tmp and restore APT configuration after installation
########################################################################################################################

INSTALLER_SCRIPT_FOLDER="/imagegeneration"
DOCKER_ASSETS="$INSTALLER_SCRIPT_FOLDER/docker-assets"

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

cleanup() {
    log "[cleanup] Starting cleanup..."

    log "[cleanup] Clearing '/tmp/*'..."
    rm -rf /tmp/*

    log "[cleanup] Clearing '$INSTALLER_SCRIPT_FOLDER/tmp'..."
    rm -rf "$INSTALLER_SCRIPT_FOLDER/tmp" || true

    log "[cleanup] Cleanup finished."
}

restore_apt_config() {
    log "[restore] Starting APT configuration restoration..."

    # Restaurer le fichier docker-clean original
    if [ -f "$DOCKER_ASSETS/apt.conf.d/docker-clean.bak" ]; then
        log "[restore] Restoring /etc/apt/apt.conf.d/docker-clean..."
        mv "$DOCKER_ASSETS/apt.conf.d/docker-clean.bak" "/etc/apt/apt.conf.d/docker-clean" || \
            fail "Failed to restore docker-clean configuration"
    else
        warn "[restore] Backup file $DOCKER_ASSETS/apt.conf.d/docker-clean.bak not found"
    fi

    # Supprimer le lien symbolique zz-force-apt-cache.conf
    if [ -L "/etc/apt/apt.conf.d/zz-force-apt-cache.conf" ]; then
        log "[restore] Removing symlink /etc/apt/apt.conf.d/zz-force-apt-cache.conf..."
        rm -f "/etc/apt/apt.conf.d/zz-force-apt-cache.conf" || \
            fail "Failed to remove zz-force-apt-cache.conf symlink"
    fi

    log "[restore] APT configuration restoration finished."
}

# Exécuter les fonctions si le script est appelé directement
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    cleanup
    restore_apt_config
fi