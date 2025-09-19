#!/bin/bash -e
################################################################################
##  File:  docker-build/install-prereqs.sh
##  Desc:  Install prerequisites of "gha-runner-compose" image: 
##         GitHub Actions Runner, pwsh with basic modules
################################################################################

# ===== CONFIGURATION ===== #
set -Eeo pipefail

export INSTALLER_SCRIPT_FOLDER="/imagegeneration"
export HELPER_SCRIPTS="$INSTALLER_SCRIPT_FOLDER/helpers"
export BUILD_SCRIPTS="$INSTALLER_SCRIPT_FOLDER/build"
export TEST_SCRIPTS="$INSTALLER_SCRIPT_FOLDER/tests"
export TOOLSET_FILE="$INSTALLER_SCRIPT_FOLDER/toolset.json"
export DOCKER_BUILD="$INSTALLER_SCRIPT_FOLDER/docker-build"
export LOCAL_INSTALL="$DOCKER_BUILD/local-install"
export IMAGE_OS=$(echo "$(lsb_release -ds)" | sed 's/Ubuntu //')

PREREQUISITES_SCRIPTS=(
    "$BUILD_SCRIPTS/configure-apt.sh"
    "$BUILD_SCRIPTS/configure-environment.sh"
    "$BUILD_SCRIPTS/install-apt-vital.sh"
    "$BUILD_SCRIPTS/install-ms-repos.sh"
)


# ===== FUNCTIONS ===== #
source "$LOCAL_INSTALL/helpers.sh"
source "$HELPER_SCRIPTS/install.sh"
source "$HELPER_SCRIPTS/etc-environment.sh"

install_runner(){
    log "Téléchargement du binaire GitHub Actions Runner"
    local repo="actions/runner"
    local url_filter="contains(\"linux-${ARCH_SHORT}\") and endswith(\".tar.gz\")"
    local url=$(resolve_github_release_asset_url "$repo" "$url_filter" "latest" "false" "true")
    local runner_tmp_tgz=$(download_with_retry "$url")
    local file_name=$(basename "$runner_tmp_tgz")
    local checksum=$(get_checksum_from_github_release "$repo" "$file_name <!-- BEGIN SHA" "latest" "SHA256")

    use_checksum_comparison "$runner_tmp_tgz" "$checksum" "256"
    tar -xzf "$runner_tmp_tgz" -C "$RUNNER_INSTALL_DIR" || fail "Extract runner tarball failed"
    rm -f "$runner_tmp_tgz"
    chown -R ${RUNNER_USER}:${RUNNER_USER} "$RUNNER_INSTALL_DIR"
    log "Runner installé dans $RUNNER_INSTALL_DIR"
}

install_powershell(){
    log "Installation PowerShell (tarball GitHub)"
    local repo="PowerShell/PowerShell"
    local version=$(get_toolset_value ".pwsh.version")
    local url_filter="endswith(\"linux-${ARCH_SHORT}.tar.gz\")"
    local url=$(resolve_github_release_asset_url "$repo" "$url_filter" "$version" "false" "true")
    local major_version="${version%%.*}"
    local dest_dir="/opt/microsoft/powershell/${major_version}"
    local pwsh_tmp_tgz=$(download_with_retry "$url")
    local file_name=$(basename "$pwsh_tmp_tgz")
    local hash_url="${url%/*}/hashes.sha256"
    local checksum=$(get_checksum_from_url "$hash_url" "$file_name" "SHA256")

    use_checksum_comparison "$pwsh_tmp_tgz" "$checksum" "256"
    mkdir -p "$dest_dir"
    tar -xzf "$pwsh_tmp_tgz" -C "$dest_dir" || fail "Extract pwsh tarball failed"
    chmod +x "$dest_dir/pwsh"
    ln -sf "$dest_dir/pwsh" /usr/bin/pwsh
    rm -f "$pwsh_tmp_tgz"
    pwsh -v || fail "pwsh non fonctionnel après installation"
    log "PowerShell installé (pwsh disponible dans /usr/bin/pwsh)"
}

install_pwsh_modules(){
    log "Préparation tests + installation modules PowerShell officiels"
    local script="${LOCAL_INSTALL}/Install-PowerShellModules.ps1"
    if [ ! -f "$script" ]; then
    log "Script officiel introuvable ($script) -> skip"
    return 0
    fi
    # Exécuter le script (installe aussi Pester puis lance les tests PowerShellModules)
    pwsh -NoLogo -File "$script" || fail "Echec installation modules PowerShell officiels"
}

run_prerequisites_scripts(){
    log "Running prerequisites scripts"

    # apt package list required for prerequisites scripts
    apt-get update

    # Adapt content of configure-environment.sh for container context
    sed -i 's/^\(.*waagent.*\)$/# \1/g' "$BUILD_SCRIPTS/configure-environment.sh"
    sed -i 's/^\(.*\/etc\/hosts.*\)$/# \1/g' "$BUILD_SCRIPTS/configure-environment.sh"
    sed -i 's/^\(.*sysctl.*\)$/# \1/g' "$BUILD_SCRIPTS/configure-environment.sh"
    sed -i 's/^\(.*motd-news.*\)$/# \1/g' "$BUILD_SCRIPTS/configure-environment.sh"

    for script in "${PREREQUISITES_SCRIPTS[@]}"; do
        if [ -f "$script" ]; then
            log "Running prerequisite script: $(basename "$script")"
            bash -e "$script" 
            reload_etc_environment
        else
            fail "Prerequisite script not found: $(basename "$script")"
        fi
    done

    log "Prerequisites scripts completed"
}


# ===== RUN ===== #
log "========== RUN : install-prereqs.sh =========="
mkdir -p "$INSTALLER_SCRIPT_FOLDER/tmp"
cd "$INSTALLER_SCRIPT_FOLDER/tmp"

# Enable cache-aware curl/wget wrappers for downstream scripts + fake systemctl
if [ -d "$DOCKER_BUILD/bin" ]; then
    chmod +x "$DOCKER_BUILD/bin"/* || true
    export PATH="$DOCKER_BUILD/bin:$PATH"
    log "=> Enabled cache-aware download wrappers (curl/wget) + fake systemctl"
fi

# install_runner
install_powershell
install_pwsh_modules
run_prerequisites_scripts

log "========== END : install-prereqs.sh =========="