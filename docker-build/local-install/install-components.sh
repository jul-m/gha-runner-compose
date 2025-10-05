#!/bin/bash -e
########################################################################################################################
##  File:  docker-build/local-install/install-components.sh
##  Desc:  Install selected components of "gha-runner-compose" image. Runned by Dockerfile.
########################################################################################################################

# ===== CONFIGURATION ===== #
set -euo pipefail

export INSTALLER_SCRIPT_FOLDER="/imagegeneration"
export HELPER_SCRIPTS="$INSTALLER_SCRIPT_FOLDER/helpers"
export BUILD_SCRIPTS="$INSTALLER_SCRIPT_FOLDER/build"
export TEST_SCRIPTS="$INSTALLER_SCRIPT_FOLDER/tests"
export TOOLSET_FILE="$INSTALLER_SCRIPT_FOLDER/toolset.json"
export DOCKER_BUILD="$INSTALLER_SCRIPT_FOLDER/docker-build"
export LOCAL_INSTALL="$DOCKER_BUILD/local-install"
export SUDO_USER=${RUNNER_USER}

COMPONENTS_SCRIPTS="$DOCKER_BUILD/components"
COMPONENTS_CSV="$LOCAL_INSTALL/components.csv"
RELOAD_ETC_ENV_COMPONENTS=("python")

# Dynamic arrays populated from CSV
declare -A COMPONENT_PLATFORM=()
declare -A COMPONENT_CATEGORIES=()
declare -A COMPONENT_DEPENDS=()
declare -A CATEGORIES=()

# Global variables for dependency resolution
declare -a resolved_deps=()
declare -a visiting_deps=()

# Array to store already installed components, APT packages and PWSH modules
declare -A INSTALLED_COMPONENTS=()
declare -A INSTALLED_APT_PACKAGES=()
declare -A INSTALLED_PWSH_MODULES=()

# Split RUNNER_COMPONENTS build env var values into array
IFS=',' read -ra components <<< "${RUNNER_COMPONENTS:-}"


# ===== FUNCTIONS ===== #
source "$LOCAL_INSTALL/helpers.sh"
source "$HELPER_SCRIPTS/install.sh"
source "$HELPER_SCRIPTS/etc-environment.sh"

# Remove duplicates from a named array (in-place)
# Usage: dedup_components array_name
dedup_components() {
    local arr_name="$1"

    # If no array name provided, nothing to do
    [ -z "$arr_name" ] && return 0

    # Use a nameref to refer to the array passed by name (bash 4.3+)
    local -n comp_to_dedup="$arr_name"
    local -a final_deduped=()
    local -A _seen=()
    for comp in "${comp_to_dedup[@]}"; do
        if [ -z "${_seen[$comp]+_}" ]; then
            final_deduped+=("$comp")
            _seen[$comp]=1
        fi
    done

    # Overwrite the original array with the deduped values
    comp_to_dedup=("${final_deduped[@]}")
}

# Filter out lite components if their full version is present
# Usage: filter_lite_components array_name
filter_lite_components() {
    local arr_name="$1"

    # If no array name provided, nothing to do
    [ -z "$arr_name" ] && return 0

    # Use a nameref to refer to the array passed by name (bash 4.3+)
    local -n comp_to_filter="$arr_name"
    local -a filtered=()
    local -A full_components=()

    # First pass: collect all non-lite components
    for comp in "${comp_to_filter[@]}"; do
        if [[ "$comp" != *-lite ]]; then
            full_components["$comp"]=1
        fi
    done

    # Second pass: filter out lite components if full version exists
    for comp in "${comp_to_filter[@]}"; do
        if [[ "$comp" == *-lite ]]; then
            # Extract the base component name (remove -lite suffix)
            local base_comp="${comp%-lite}"
            if [[ ${full_components[$base_comp]+isset} ]]; then
                log "=> Ignoring lite component '${comp}': full version '${base_comp}' is present"
                continue
            fi
        fi
        filtered+=("$comp")
    done

    # Overwrite the original array with the filtered values
    comp_to_filter=("${filtered[@]}")
}

# Load installed items from file (generic function)
load_installed_items() {
    local type="$1"
    local file="$INSTALLER_SCRIPT_FOLDER/installed/${type}.txt"
    local upper_type="${type^^}"
    local arr_name="INSTALLED_${upper_type//-/_}"
    declare -n arr_ref="$arr_name"
    arr_ref=()
    if [ -f "$file" ]; then
        while IFS= read -r item; do
            item=$(echo "$item" | xargs)
            [ -n "$item" ] && arr_ref["$item"]=1
        done < "$file"
        log "Loaded ${#arr_ref[@]} installed $type from $file"
        if [ ${#arr_ref[@]} -gt 0 ]; then
            log "Installed $type: $(printf '%s ' "${!arr_ref[@]}" | sort)"
        fi
    else
        log "No installed $type file found, assuming none installed"
    fi
}

# Save installed items to file (generic function)
save_installed_items() {
    local type="$1"
    local file="$INSTALLER_SCRIPT_FOLDER/installed/${type}.txt"
    local upper_type="${type^^}"
    local arr_name="INSTALLED_${upper_type//-/_}"
    declare -n arr_ref="$arr_name"
    if [ ${#arr_ref[@]} -gt 0 ]; then
        # Special handling for components: filter out lite versions if full version exists
        if [ "$type" == "components" ]; then
            local -a components_to_save=()
            local -A full_components=()
            
            # First pass: collect all non-lite components
            for comp in "${!arr_ref[@]}"; do
                if [[ "$comp" != *-lite ]]; then
                    full_components["$comp"]=1
                fi
            done
            
            # Second pass: filter out lite components if full version exists
            for comp in "${!arr_ref[@]}"; do
                if [[ "$comp" == *-lite ]]; then
                    # Extract the base component name (remove -lite suffix)
                    local base_comp="${comp%-lite}"
                    if [[ ${full_components[$base_comp]+isset} ]]; then
                        log "=> Ignoring lite component '${comp}' in saved list: full version '${base_comp}' is present"
                        continue
                    fi
                fi
                components_to_save+=("$comp")
            done
            
            # Save filtered components
            printf '%s\n' "${components_to_save[@]}" | sort > "$file"
            log "Saved ${#components_to_save[@]} installed $type to $file (after filtering lite versions)"
        else
            for item in "${!arr_ref[@]}"; do
                echo "$item"
            done | sort > "$file"
            log "Saved ${#arr_ref[@]} installed $type to $file"
        fi
    else
        rm -f "$file"
        log "No $type installed, removed $file"
    fi
}

# Load components data from CSV
load_components_csv() {
    if [ ! -f "$COMPONENTS_CSV" ]; then
        fail "Components CSV not found: $COMPONENTS_CSV"
    fi

    log "=> Loading components data from $COMPONENTS_CSV"
    while IFS=',' read -r component platform categories depends_on; do
        # Skip header
        [ "$component" == "component" ] && continue
        # Trim spaces
        component=$(echo "$component" | xargs)
        platform=$(echo "$platform" | xargs)
        categories=$(echo "$categories" | xargs)
        depends_on=$(echo "$depends_on" | xargs)

        COMPONENT_PLATFORM["$component"]="$platform"
        COMPONENT_CATEGORIES["$component"]="$categories"
        COMPONENT_DEPENDS["$component"]="$depends_on"
        
        # Split categories and add component to each
        IFS='|' read -ra cat_list <<< "$categories"
        for cat in "${cat_list[@]}"; do
            cat=$(echo "$cat" | xargs)
            if [ -n "$cat" ]; then
                CATEGORIES["$cat"]="${CATEGORIES["$cat"]:-} $component"
            fi
        done
    done < "$COMPONENTS_CSV"
}

# Expand categories and 'all' into component list
expand_components() {
    local expanded=()
    local processed=()

    # Checks for 'all' or 'all-<category>'
    for item in "${components[@]}"; do
        item=$(echo "$item" | xargs)
        if [ "$item" == "all" ]; then
            # Check if 'all' is alone
            if [ ${#components[@]} -gt 1 ]; then
                fail "'all' can only be used alone in RUNNER_COMPONENTS"
            fi
        elif [[ "$item" == all-* ]]; then
            # Check if category exists
            local category="${item#all-}"
            if [[ ! "${CATEGORIES[$category]+isset}" ]]; then
                fail "Category '$category' not found in components.csv"
            fi
        fi
    done

    # Expand
    for item in "${components[@]}"; do
        item=$(echo "$item" | xargs)
        if [ "$item" == "all" ]; then
            # Add all compatible components (excluding lite versions)
            for comp in "${!COMPONENT_PLATFORM[@]}"; do
                local plat="${COMPONENT_PLATFORM[$comp]}"
                if [ "$plat" == "all" ] || [ "$plat" == "$ARCH_SHORT" ]; then
                    # Skip lite components when using 'all'
                    if [[ "$comp" == *-lite ]]; then
                        continue
                    fi
                    if [[ ! " ${processed[*]} " == *" $comp "* ]]; then
                        expanded+=("$comp")
                        processed+=("$comp")
                    fi
                fi
            done
        elif [[ "$item" == all-* ]]; then
            local category="${item#all-}"
            # Add all compatible components in category
            local comp_list
            IFS=' ' read -ra comp_list <<< "${CATEGORIES[$category]}"
            for comp in "${comp_list[@]}"; do
                local plat="${COMPONENT_PLATFORM[$comp]}"
                if [ "$plat" == "all" ] || [ "$plat" == "$ARCH_SHORT" ]; then
                    if [[ ! " ${processed[*]} " == *" $comp "* ]]; then
                        expanded+=("$comp")
                        processed+=("$comp")
                    fi
                fi
            done
        elif [[ "${COMPONENT_PLATFORM[$item]+isset}" ]]; then
            # It's a component
            if [[ ! " ${processed[*]} " == *" $item "* ]]; then
                expanded+=("$item")
                processed+=("$item")
            fi
        else
            fail "Component '$item' not found in components.csv"
        fi
    done

    components=("${expanded[@]}")
    dedup_components components
}

# Helper function for resolving dependencies
resolve_dep() {
    local comp="$1"
    if [[ " ${resolved_deps[*]} " == *" $comp "* ]]; then
        return
    fi
    if [[ " ${visiting_deps[*]} " == *" $comp "* ]]; then
        warn "Dependency cycle detected for $comp, skipping"
        return
    fi
    visiting_deps+=("$comp")

    local deps="${COMPONENT_DEPENDS[$comp]}"
    if [ -n "$deps" ]; then
        IFS='|' read -ra dep_list <<< "$deps"
        for dep in "${dep_list[@]}"; do
            dep=$(echo "$dep" | xargs)
            # If the dependency is not present in COMPONENT_PLATFORM it means
            # it wasn't defined in components.csv — treat that as an error
            if [[ ! "${COMPONENT_PLATFORM[$dep]+isset}" ]]; then
                fail "Component dependency '$dep' referenced by '$comp' not found in $COMPONENTS_CSV"
            fi
            resolve_dep "$dep"
        done
    fi

    visiting_deps=("${visiting_deps[@]/$comp}")
    resolved_deps+=("$comp")
}

# Resolve dependencies (simple topological sort, no cycle detection)
resolve_dependencies() {
    resolved_deps=()
    visiting_deps=()

    local temp_components=("${components[@]}")
    components=()
    for comp in "${temp_components[@]}"; do
        resolve_dep "$comp"
    done
    components=("${resolved_deps[@]}")
    dedup_components components
}

# Update toolset.json for ARM64 if needed
update_toolset_file() {
    if [ -f "$TOOLSET_FILE" ]; then
        log "=> Updating toolset file: $TOOLSET_FILE"

        if is_arm64; then
            log "Adapting toolset file for arm64"
            sed -i 's/"asset": "linux-amd64"/"asset": "linux-arm64"/g' "$TOOLSET_FILE"
            sed -i 's/"asset": "linux-x86_64"/"asset": "linux-aarch64"/g' "$TOOLSET_FILE"
        fi
    else
        fail "Toolset file not found: $TOOLSET_FILE"
    fi
}

process_component() {
    local name="$1"
    [ -z "$name" ] && return 0

    # Check if component should be skipped
    if [[ " ${SKIP_COMPONENTS_PREREQS[*]} " == *" $name "* ]]; then
        warn "=> Skipping component '${name}': already installed in prerequisites step."
        return 0
    fi

    # Check if component is AMD64 only on ARM64 system
    if [[ "${COMPONENT_PLATFORM["$name"]}" != "all" && "${COMPONENT_PLATFORM["$name"]}" != "$ARCH_SHORT" ]]; then
        fail "Component '${name}' is not available on $ARCH_SHORT architecture, cannot proceed with installation."
    fi

    local local_script="$COMPONENTS_SCRIPTS/${name}.sh"
    local build_script="$BUILD_SCRIPTS/install-${name}.sh"

    if [ -f "$local_script" ]; then
        # If "local" script exists for component, use it
        log "=> Installing component '${name}' via local script $(basename "$local_script")"
        bash -eo pipefail "$local_script" || fail "Local install failed for component '${name}'"
        log "✓ Component '${name}' installed via local script"
    elif [ -f "$build_script" ]; then
        # Elif "upstream" script exists for component, use it
        log "=> Installing component '${name}' via upstream script $(basename "$build_script")"
        bash -eo pipefail "$build_script" || fail "Upstream install failed for component '${name}'"
        log "✓ Component '${name}' installed via upstream script"
    else
        # Else, no script found, error out
        fail "No script found for component '${name}' in local or upstream locations"
    fi

    if [[ " ${RELOAD_ETC_ENV_COMPONENTS[*]} " == *" $c "* ]]; then
        log "Reloading /etc/environment after installation of component '$c'"
        reload_etc_environment
    fi

    # Fix permissions on runner user home directory
    chown -R ${RUNNER_USER}:${RUNNER_USER} /home/${RUNNER_USER}

    INSTALLED_COMPONENTS["$name"]=1
    echo ""

    return 0
}

# Steps to run before installing components
run_preinstall() {
    log "Running pre-installation steps"

    # Load packages lists for components scripts with "apt-get install"
    log "=> Preloading apt packages lists"
    apt-get update

     # Enable cache-aware curl/wget wrappers for downstream scripts + fake systemctl
    if [ -d "$DOCKER_BUILD/bin" ]; then
        chmod +x "$DOCKER_BUILD/bin"/* || true
        export PATH="$DOCKER_BUILD/bin:$PATH"
        cp "$DOCKER_BUILD/bin/systemctl" /usr/bin/systemctl
        log "=> Enabled cache-aware download wrappers (curl/wget) + fake systemctl"
    fi

    mkdir -p "$INSTALLER_SCRIPT_FOLDER/installed"

    reload_etc_environment
    log "Pre-installation steps completed"
}

# Steps to run after installing components
run_postinstall() {
    log "Running post-installation steps"
    
    # Fix permissions on /opt/hostedtoolcache/
    if [ -d "/opt/hostedtoolcache/" ]; then
        log "Fixing permissions on /opt/hostedtoolcache/"
        chown -R ${RUNNER_USER}:${RUNNER_USER} /opt/hostedtoolcache/
    fi

    log "Post-installation steps completed"
}

# Install additional APT packages if APT_PACKAGES is set
install_apt_packages() {
    if [ -n "${APT_PACKAGES}" ]; then
        log "Installing additional APT packages: ${APT_PACKAGES}"
        local packages=$(echo "${APT_PACKAGES}" | tr ',' ' ')
        apt-get update && apt-get install -y --no-install-recommends $packages
        log "✓ Additional APT packages installed"
        
        # Mark packages as installed
        for pkg in $packages; do
            INSTALLED_APT_PACKAGES["$pkg"]=1
        done
        save_installed_items "apt-packages"
    else
        log "No additional APT packages to install"
    fi
}

# Install additional PowerShell modules if PWSH_MODULES is set
install_pwsh_modules() {
    if [ -n "${PWSH_MODULES}" ]; then
        log "Installing additional PowerShell modules: ${PWSH_MODULES}"
        PWSH_MODULES=${PWSH_MODULES} pwsh -Command "& /imagegeneration/docker-build/local-install/Install-PowerShellModules.ps1"
        log "✓ Additional PowerShell modules installed"
        
        # Mark modules as installed
        IFS=',' read -ra modules <<< "${PWSH_MODULES}"
        for mod in "${modules[@]}"; do
            mod=$(echo "$mod" | xargs)
            INSTALLED_PWSH_MODULES["$mod"]=1
        done
        save_installed_items "pwsh-modules"
    else
        log "No additional PowerShell modules to install"
    fi
}


# ===== RUN ===== #
log "========== RUN : install-components.sh =========="
mkdir -p "$INSTALLER_SCRIPT_FOLDER/tmp"
cd "$INSTALLER_SCRIPT_FOLDER/tmp"

run_preinstall
load_installed_items "components"
load_installed_items "apt-packages"
load_installed_items "pwsh-modules"
update_toolset_file

if [ ${#components[@]} -eq 0 ]; then
    warn "No components requested for installation."
else
    load_components_csv
    expand_components
    resolve_dependencies
    filter_lite_components components

    echo ""
    log "=> Installing requested components: $(printf '%s ' "${components[@]}")"

    for c in "${components[@]}"; do
        if [[ ${INSTALLED_COMPONENTS[$c]+isset} ]]; then
            log "=> Skipping component '${c}': already installed."
            continue
        fi
        
        # Check if this is a lite component and its full version is already installed
        if [[ "$c" == *-lite ]]; then
            base_comp="${c%-lite}"
            if [[ ${INSTALLED_COMPONENTS[$base_comp]+isset} ]]; then
                log "=> Skipping lite component '${c}': full version '${base_comp}' is already installed."
                continue
            fi
        fi
        
        process_component "$c"
    done

    log "All requested components processed"
fi

run_postinstall
install_apt_packages
install_pwsh_modules
save_installed_items "components"
save_installed_items "apt-packages"
save_installed_items "pwsh-modules"

log "========== END : install-components.sh =========="