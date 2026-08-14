#!/bin/bash -e
########################################################################################################################
##  File:  docker-build/local-install/install-prereqs.sh
##  Desc:  Install prerequisites of "gha-runner-compose" image. Runned by Dockerfile.
########################################################################################################################

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

patch_upstream_helpers(){
    log "Patching upstream helpers/install.sh (fix unquoted echo bugs)"
    local install_sh="$HELPER_SCRIPTS/install.sh"

    # Upstream uses `printf "$(echo $var | jq '.body')\n"` which is doubly broken:
    #   1. The format string is user-controlled → printf format injection risk.
    #   2. The inner `echo $var` is unquoted → jq receives word-split JSON, not a single string.
    # Replace the whole line before the generic echo→printf patches below alter the anchor text.
    sed -i '/printf.*echo.*matching_releases.*body/c\    matched_line=$(printf '"'"'%s'"'"' "$matching_releases" | jq -r '"'"'.body'"'"' | grep "$file_name")' "$install_sh"

    # Upstream passes large JSON blobs through unquoted `echo $var | jq …`.
    # Without quotes, bash performs word-splitting and globbing on the JSON before jq sees it,
    # which silently corrupts data containing spaces, newlines, or shell metacharacters.
    # Fix: replace every `echo $var |` with `printf '%s' "$var" |` (quoted, no expansion).
    sed -i -E 's/echo \$([a-zA-Z_]+) [|]/printf '"'"'%s'"'"' "\$\1" |/g' "$install_sh"

    # Same word-splitting issue for bare `echo $var` used as a return value (last line of a
    # function or end-of-block). Replace with `printf '%s\n'` which preserves the exact value.
    sed -i -E 's/^([[:space:]]+)echo \$([a-zA-Z_]+)$/\1printf '"'"'%s\\n'"'"' "\$\2"/' "$install_sh"

    # Upstream uses `printf "$checksums\n"` to feed a downloaded checksum file into grep.
    # Using a variable as the printf format string is a format-injection vulnerability:
    # if the file content contains %, printf interprets them as format specifiers and crashes.
    # Fix: use a literal format string '%s\n' and pass the variable as an argument.
    sed -i 's|printf "\$checksums\\n"|printf '"'"'%s\\n'"'"' "\$checksums"|' "$install_sh"

    # Upstream reads the checksum file with `checksums=$(cat …)`, which silently drops null
    # bytes (NUL, \000) and may keep Windows-style carriage returns (\r).  Both corrupt the
    # sha256 hash comparison that follows.  Use `tr -d` to strip them explicitly.
    sed -i 's|checksums=$(cat "$checksums_file_path")|checksums=$(tr -d '"'"'\\000\\r'"'"' < "$checksums_file_path")|' "$install_sh"
}

patch_upstream_build_scripts(){
    log "Patching upstream build scripts for Docker compatibility"
    local env_sh="$BUILD_SCRIPTS/configure-environment.sh"

    # Upstream configure-environment.sh runs:
    #   echo "set man-db/auto-update false" | debconf-communicate
    #   dpkg-reconfigure man-db
    # In a Docker build, configure-environment runs early (before install-apt-vital.sh installs
    # man-db), so man-db is not yet present and both commands fail.
    # Workaround: preseed debconf directly via debconf-set-selections (available from the base
    # image), then comment out the two upstream lines so they never execute.
    if command -v debconf-set-selections >/dev/null 2>&1; then
        echo "man-db man-db/auto-update boolean false" | debconf-set-selections
    fi
    sed -i '/debconf-communicate/s/^/# /' "$env_sh"
    sed -i '/dpkg-reconfigure man-db/s/^/# /' "$env_sh"
}

# Patch install.sh on disk BEFORE sourcing so fixed functions are loaded
patch_upstream_helpers
source "$HELPER_SCRIPTS/install.sh"
source "$HELPER_SCRIPTS/etc-environment.sh"

install_powershell(){
    log "Installing PowerShell from GitHub archive..."
    local repo="PowerShell/PowerShell"
    local version url_filter url major_version dest_dir pwsh_tmp_tgz file_name hash_url checksum
    version=$(get_toolset_value ".pwsh.version") || fail "Cannot get pwsh version from toolset"
    url_filter="endswith(\"linux-${ARCH_SHORT}.tar.gz\")"
    url=$(resolve_github_release_asset_url "$repo" "$url_filter" "$version" "false" "true") \
        || fail "Cannot resolve PowerShell download URL (version=$version, arch=$ARCH_SHORT)"
    major_version="${version%%.*}"
    dest_dir="/opt/microsoft/powershell/${major_version}"
    pwsh_tmp_tgz=$(download_with_retry "$url") || fail "Cannot download PowerShell tarball"
    file_name=$(basename "$pwsh_tmp_tgz")
    hash_url="${url%/*}/hashes.sha256"
    checksum=$(get_checksum_from_url "$hash_url" "$file_name" "SHA256") \
        || fail "Cannot get PowerShell checksum"

    use_checksum_comparison "$pwsh_tmp_tgz" "$checksum" "256"
    mkdir -p "$dest_dir"
    tar -xzf "$pwsh_tmp_tgz" -C "$dest_dir" || fail "Extract pwsh tarball failed"
    chmod +x "$dest_dir/pwsh"
    ln -sf "$dest_dir/pwsh" /usr/bin/pwsh
    rm -f "$pwsh_tmp_tgz"
    pwsh -v || fail "pwsh not working"
    log "PowerShell installed (pwsh available in /usr/bin/pwsh)"
}

install_pwsh_modules(){
    log "Preparing tests + installing base PowerShell modules..."
    local script="${LOCAL_INSTALL}/Install-PowerShellModules.ps1"
    if [ ! -f "$script" ]; then
    log "Install-PowerShellModules.ps1 not found ($script) -> skip"
    return 0
    fi
    # Execute the script (also installs Pester and runs PowerShellModules tests)
    pwsh -NoLogo -File "$script" || fail "Failed to install base PowerShell modules"
}

run_prerequisites_scripts(){
    log "Running prerequisites scripts"

    patch_upstream_build_scripts

    # apt package list required for prerequisites scripts
    apt-get update

    # Adapt content of upstream configure-environment.sh for container context
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

install_powershell
install_pwsh_modules
run_prerequisites_scripts

log "========== END : install-prereqs.sh =========="