#!/bin/bash
########################################################################################################################
##  File:  docker-build/local-install/run-component-tests.sh
##  Desc:  Re-test every installed component against the finished image: replay
##         its Pester test (docker-assets/from-upstream/build/install-<name>.sh's
##         trailing invoke_tests call) if still active, then its custom test
##         script (docker-build/tests/<name>.sh) if one exists. Everything this
##         needs is already baked into the image, so it runs standalone with no
##         host mounts - as a GitHub Actions step on a booted runner, or via
##         `docker run --entrypoint bash <image> -c ...` from anywhere else.
########################################################################################################################

set -uo pipefail

export INSTALLER_SCRIPT_FOLDER="/imagegeneration"
export HELPER_SCRIPTS="$INSTALLER_SCRIPT_FOLDER/helpers"
export BUILD_SCRIPTS="$INSTALLER_SCRIPT_FOLDER/build"
export DOCKER_BUILD="$INSTALLER_SCRIPT_FOLDER/docker-build"
CUSTOM_TESTS_DIR="$DOCKER_BUILD/tests"
INSTALLED_FILE="$INSTALLER_SCRIPT_FOLDER/installed/components.txt"

source "$DOCKER_BUILD/local-install/helpers.sh"

if [ ! -f "$INSTALLED_FILE" ]; then
    log "No installed components recorded ($INSTALLED_FILE) - nothing to test."
    exit 0
fi

FAILED=()

test_component() {
    local component="$1"
    local ran_something=false

    local build_script="$BUILD_SCRIPTS/install-${component}.sh"
    if [ -f "$build_script" ]; then
        local line
        line=$(grep -m1 '^invoke_tests[[:space:]]' "$build_script" || true)
        # invoke_tests is called with 1 or 2 quoted args across different
        # install scripts (e.g. install-apt-common.sh passes only one) -
        # bash's own regex captures whichever are actually there.
        if [[ "$line" =~ ^invoke_tests[[:space:]]+\"([^\"]*)\"([[:space:]]+\"([^\"]*)\")?$ ]]; then
            local test_file="${BASH_REMATCH[1]}" test_name="${BASH_REMATCH[3]:-}"
            ran_something=true
            if invoke_tests "$test_file" "$test_name"; then
                log "✓ Pester test passed for '${component}' (${test_file} / ${test_name})"
            else
                warn "✗ Pester test FAILED for '${component}' (${test_file} / ${test_name})"
                FAILED+=("${component} (pester)")
            fi
        fi
    fi

    local custom_script="$CUSTOM_TESTS_DIR/${component}.sh"
    if [ -f "$custom_script" ]; then
        ran_something=true
        if bash "$custom_script"; then
            log "✓ Custom test passed for '${component}'"
        else
            warn "✗ Custom test FAILED for '${component}'"
            FAILED+=("${component} (custom)")
        fi
    fi

    if [ "$ran_something" == "false" ]; then
        log "=> No test defined for '${component}', skipping"
    fi
}

log "========== RUN : run-component-tests.sh =========="
while IFS= read -r component; do
    [ -z "$component" ] && continue
    test_component "$component"
done < "$INSTALLED_FILE"

if [ ${#FAILED[@]} -gt 0 ]; then
    # helpers.sh sets IFS to newline+tab, so ${FAILED[*]} joined by the
    # default IFS would spread one entry per line instead of a single list.
    fail "Component test failures: $(IFS=', '; echo "${FAILED[*]}")"
fi

log "All component tests passed (or had none defined)."
log "========== END : run-component-tests.sh =========="
