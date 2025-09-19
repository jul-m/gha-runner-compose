#!/bin/bash -e
################################################################################
##  File:  docker-build/components/homebrew.sh
##  Desc:  Override install-homebrew.sh script to use correct user
################################################################################

source "$LOCAL_INSTALL/helpers.sh"

script="$BUILD_SCRIPTS/install-homebrew.sh"

if [ ! -f "$script" ]; then
    fail "Missing upstream script for homebrew: $script"
fi

chown -R "root":"$SUDO_USER" "/imagegeneration/"
log "Running install-homebrew.sh as user $SUDO_USER"

sudo -u "$SUDO_USER" /bin/sh -c "HELPER_SCRIPTS=$HELPER_SCRIPTS INSTALLER_SCRIPT_FOLDER=$INSTALLER_SCRIPT_FOLDER $script"