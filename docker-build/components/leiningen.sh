#!/bin/bash
################################################################################
##  File:  docker-build/components/leiningen.sh
##  Desc:  Override install-leiningen.sh to make the self-installed jar
##         readable by the runner user (root-only by default)
################################################################################

source "$LOCAL_INSTALL/helpers.sh"

script="$BUILD_SCRIPTS/install-leiningen.sh"

if [ ! -f "$script" ]; then
    fail "Missing upstream script for leiningen: $script"
fi

sh -c "$script" || fail "leiningen install failed"

chmod -R a+rX /usr/local/lib/lein

log "leiningen installed"
