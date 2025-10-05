#!/bin/bash
########################################################################################################################
##  File:  entrypoint.sh
##  Desc:  Entrypoint script to run GitHub Actions Runner inside the container
########################################################################################################################

# =============================================================================
# CONFIGURATION
# =============================================================================

set -Eeo pipefail

# Required environment variables validation
if [ -z "${RUNNER_TOKEN:-}" ]; then
    fail "RUNNER_TOKEN must be provided for registration"
fi

# Global constants and variables
RUNNER_USER="${RUNNER_USER:-runner}"
RUNNER_NAME="${RUNNER_NAME:-$(hostname | cut -c-12)}"
RUNNER_LABELS="${RUNNER_LABELS:-docker-runner,docker-runner-$ARCH_SHORT,$RUNNER_NAME}"
WORKDIR="${RUNNER_WORKDIR:-/home/$RUNNER_USER/work}"
INSTALL_DIR="${RUNNER_INSTALL_DIR:-/opt/actions-runner}"
RUNNER_CACHE_DIR="/opt/runner-cache"

# Build environment paths (only when needed)
INSTALLER_SCRIPT_FOLDER="/imagegeneration"
HELPER_SCRIPTS="$INSTALLER_SCRIPT_FOLDER/helpers"
DOCKER_BUILD="$INSTALLER_SCRIPT_FOLDER/docker-build"
LOCAL_INSTALL="$DOCKER_BUILD/local-install"


# =============================================================================
# FUNCTIONS
# =============================================================================

# Source required helper functions
source "$LOCAL_INSTALL/helpers.sh"
source "$HELPER_SCRIPTS/install.sh"


# Extract GitHub Actions Runner from cache if available
# Returns:
#   0 if runner was extracted from cache
#   1 if no cached runner was found
extract_runner_from_cache() {
    log "Looking for cached runner..."
    local pattern="actions-runner-linux-${ARCH_SHORT}-*.tar.gz"
    local runner_tmp_tgz=$(ls -v $RUNNER_CACHE_DIR/$pattern 2>/dev/null | tail -1 || true)
    
    if [ -n "$runner_tmp_tgz" ]; then
        log "Extracting runner from cache: $runner_tmp_tgz"
        tar -xzf "$runner_tmp_tgz" -C "$INSTALL_DIR" || fail "Failed to extract runner"
        chown -R "$RUNNER_USER:$RUNNER_USER" "$INSTALL_DIR"
        log "Runner extracted from cache to $INSTALL_DIR"
        return 0
    fi
    return 1
}

# Download and extract the latest GitHub Actions Runner binary
# Downloads the runner from GitHub releases, verifies checksum, and extracts it
download_and_extract_runner() {
    log "Downloading GitHub Actions Runner binary"

    local repo="actions/runner"
    local url_filter="contains(\"linux-${ARCH_SHORT}\") and endswith(\".tar.gz\")"
    local url=$(resolve_github_release_asset_url "$repo" "$url_filter" "latest" "false" "true")
    local runner_tmp_tgz=$(download_with_retry "$url")
    local file_name=$(basename "$runner_tmp_tgz")
    local checksum=$(get_checksum_from_github_release "$repo" "$file_name <!-- BEGIN SHA" "latest" "SHA256")

    use_checksum_comparison "$runner_tmp_tgz" "$checksum" "256"
    tar -xzf "$runner_tmp_tgz" -C "$INSTALL_DIR" || fail "Failed to extract runner"
    rm -f "$runner_tmp_tgz"
    chown -R "$RUNNER_USER:$RUNNER_USER" "$INSTALL_DIR"
    log "Runner installed to $INSTALL_DIR"
}

# Ensure GitHub Actions Runner is installed
# Checks if runner is already installed, otherwise tries to extract from cache
# or downloads and installs the latest version
ensure_runner_installed() {
    # Check if runner is already installed
    if [ -f "$INSTALL_DIR/run.sh" ]; then
        log "Runner already installed in $INSTALL_DIR"
        return 0
    fi
    
    log "Runner not found in $INSTALL_DIR, installing..."
    
    # Try to extract from cache first, then download if not available
    if ! extract_runner_from_cache; then
        log "No cached runner found, downloading..."
        download_and_extract_runner
    fi
}

# Configure the GitHub Actions Runner
# Registers the runner with GitHub using the provided token and configuration
# Skips configuration if already configured
configure_runner() {
    log "Checking runner configuration..."
    
    if [ -f "$INSTALL_DIR/.runner" ] || [ -f "$INSTALL_DIR/.credentials" ]; then
        log "Existing configuration found, skipping configuration"
        return 0
    fi
    
    log "No existing configuration found: configuring runner"
    "$INSTALL_DIR/config.sh" --unattended \
        --url "$RUNNER_REPO_URL" \
        --token "$RUNNER_TOKEN" \
        --name "$RUNNER_NAME" \
        --labels "$RUNNER_LABELS" \
        --work "$WORKDIR" \
        --replace || fail "Failed to configure runner"
}

# Reload environment variables from /etc/environment
# Loads and exports environment variables, handling PATH deduplication
reload_etc_environment() {
    # Load and export environment variables from /etc/environment
    local env_file="/etc/environment"
    
    if [ ! -f "$env_file" ]; then
        return 0
    fi
    
    # Export non-PATH variables
    while IFS='=' read -r key value; do
        # Skip empty lines, comments, and PATH
        [[ -z "$key" || "$key" =~ ^[[:space:]]*# || "$key" == "PATH" ]] && continue
        
        # Remove quotes and export
        value="${value%\"}"
        value="${value#\"}"
        export "$key=$value"
    done < "$env_file"
    
    # Handle PATH separately with deduplication
    local etc_path=$(grep '^PATH=' "$env_file" 2>/dev/null | cut -d'=' -f2- | sed 's/^"//;s/"$//' || true)
    
    if [ -n "$etc_path" ]; then
        # Combine current PATH with /etc/environment PATH and deduplicate
        local combined_path="${PATH:-}:$etc_path"
        export PATH=$(echo "$combined_path" | tr ':' '\n' | awk '!seen[$0]++' | paste -sd':')
    fi
}

# Log installed components from the installed_components.txt file
log_installed_components() {
    local file="$INSTALLER_SCRIPT_FOLDER//installed/components.txt"
    if [ -f "$file" ]; then
        local components=$(cat "$file" | sort | tr '\n' ' ')
        if [ -n "$components" ]; then
            log "Installed components in image: $components"
        else
            log "No components installed in image"
        fi
    else
        log "No installed components file found"
    fi
}

# Stop the runner process gracefully
# Attempts SIGTERM first, then SIGKILL if process doesn't respond
# Returns:
#   0 on successful stop
#   1 if process couldn't be stopped
stop_runner_process() {
    local timeout=30

    if [ -n "${RUNNER_PGID:-}" ]; then
        log "Sending SIGTERM to runner process group (pgid=$RUNNER_PGID)"
        kill -TERM -"$RUNNER_PGID" 2>/dev/null || return 1

        # Wait for graceful shutdown
        for i in $(seq 1 $timeout); do
            if ! kill -0 -"$RUNNER_PGID" 2>/dev/null; then
                log "Runner stopped successfully"
                return 0
            fi
            sleep 1
        done

        warn "Runner did not exit after SIGTERM, sending SIGKILL"
        kill -KILL -"$RUNNER_PGID" 2>/dev/null || true

    elif [ -n "${RUNNER_PID:-}" ]; then
        log "PGID unknown, falling back to PID kill (pid=$RUNNER_PID)"
        kill -TERM "$RUNNER_PID" 2>/dev/null || return 1

        # Wait for graceful shutdown
        for i in $(seq 1 $timeout); do
            if ! kill -0 "$RUNNER_PID" 2>/dev/null; then
                log "Runner stopped successfully"
                return 0
            fi
            sleep 1
        done

        warn "Runner did not exit after SIGTERM, sending SIGKILL"
        kill -KILL "$RUNNER_PID" 2>/dev/null || true
    fi
}

# Handle shutdown signal and stop the runner gracefully
# Called when SIGINT, SIGTERM, or SIGQUIT is received
shutdown_runner() {
    log "Shutdown requested - stopping runner..."

    stop_runner_process

    log "Shutdown complete"
    exit 0
}

# =============================================================================
# MAIN SCRIPT
# =============================================================================

# Load environment and ensure runner is ready
reload_etc_environment
log_installed_components
ensure_runner_installed
configure_runner

# Setup signal handling
trap 'shutdown_runner' SIGINT SIGTERM SIGQUIT

# Start the runner
log "Starting runner..."
"$INSTALL_DIR/run.sh" &
readonly RUNNER_PID=$!

# Small pause to let the process start and capture its PGID
sleep 0.1
readonly RUNNER_PGID=$(ps -o pgid= "$RUNNER_PID" 2>/dev/null | tr -d ' ' || true)

log "Runner started - PID: $RUNNER_PID PGID: ${RUNNER_PGID:-unknown}"
wait "$RUNNER_PID"
