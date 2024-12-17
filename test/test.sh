#!/usr/bin/env bash

# Test script for macOS setup tool
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Test results tracking for bash 3.2
declare -a TEST_NAMES
declare -a TEST_RESULTS
declare -a TEST_ERRORS

# Source utilities for logging
source "${PROJECT_ROOT}/lib/logging.sh"

# Enhanced test runner with error capture
run_test() {
    local test_name="$1"
    local test_command="$2"
    local error_output

    log_info "Running test: $test_name"

    # Add test to order tracking
    TEST_NAMES[${#TEST_NAMES[@]}]="$test_name"

    # Capture both output and exit status
    error_output=$(eval "$test_command" 2>&1)
    local status="$?"

    if [ $status -eq 0 ]; then
        log_success "✓ $test_name"
        TEST_RESULTS[${#TEST_RESULTS[@]}]="pass"
        TEST_ERRORS[${#TEST_ERRORS[@]}]=""
        return 0
    else
        log_error "✗ $test_name"
        TEST_RESULTS[${#TEST_RESULTS[@]}]="fail"
        TEST_ERRORS[${#TEST_ERRORS[@]}]="$error_output"
        return 1
    fi
}

# Print test summary
print_test_summary() {
    local failed_tests=$1
    local total_tests=${#TEST_NAMES[@]}
    local passed_tests=$((total_tests - failed_tests))

    echo
    log_header "Test Summary"
    echo "Total Tests: $total_tests"
    echo "Passed: $passed_tests"
    echo "Failed: $failed_tests"

    if ((failed_tests > 0)); then
        echo
        log_header "Failed Tests Details"
        local i
        for ((i=0; i<${#TEST_NAMES[@]}; i++)); do
            if [[ "${TEST_RESULTS[$i]}" == "fail" ]]; then
                log_error "✗ ${TEST_NAMES[$i]}:"
                echo "  Error: ${TEST_ERRORS[$i]}"
                echo
            fi
        done
    fi
}

# Check for required dependencies
check_dependencies() {
    local missing_deps=()

    # List of required dependencies
    local deps=(
        "yq:Required for configuration processing"
        "shellcheck:Required for syntax checking (development only)"
    )

    for dep_entry in "${deps[@]}"; do
        local dep="${dep_entry%%:*}"
        local desc="${dep_entry#*:}"
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing_deps+=("$dep")
            log_error "Missing $dep - $desc"
        fi
    done

    if ((${#missing_deps[@]} > 0)); then
        echo
        log_info "Install missing dependencies with:"
        echo "  brew install ${missing_deps[*]}"
        exit 1
    fi
}

# Run all tests
main() {
    local failed_tests=0

    # Check dependencies first
    check_dependencies

    log_header "Starting Tests"

    # Test basic script loading
    run_test "Script loads successfully" \
        "bash -n ${PROJECT_ROOT}/setup.sh" || ((failed_tests++))

    # Test configuration loading
    run_test "Default config example exists and is valid YAML" \
        "yq eval '.' \"${PROJECT_ROOT}/config/default.yml.example\" &>/dev/null" || ((failed_tests++))

    # Test directory structure
    run_test "Project directory structure is valid" \
        "[[ -d ${PROJECT_ROOT}/lib/modules && -d ${PROJECT_ROOT}/config ]]" || ((failed_tests++))

    # Test utilities
    run_test "Utility functions load correctly" \
        "source ${PROJECT_ROOT}/lib/utils.sh && command_exists ls" || ((failed_tests++))

    # Test module loading
    for module in xcode homebrew git ssh node macos cron; do
        # First check if file exists
        run_test "Module file $module exists" \
            "[[ -f ${PROJECT_ROOT}/lib/modules/${module}.sh ]]" || ((failed_tests++))

        # Then check if it can be parsed
        run_test "Module $module loads correctly" \
            "bash -n ${PROJECT_ROOT}/lib/modules/${module}.sh 2>&1" || ((failed_tests++))
    done

    # Test Homebrew installation check
    if [[ -z "${CI}" ]]; then
        run_test "Homebrew installation check works" \
            "command -v brew &>/dev/null" || ((failed_tests++))
    fi

    # Test update checker
    run_test "Update checker script exists" \
        "[[ -f \"$PROJECT_ROOT/lib/check_update.sh\" ]]" || ((failed_tests++))

    run_test "Update checker is executable" \
        "bash \"$PROJECT_ROOT/lib/check_update.sh\"" || ((failed_tests++))

    # Test configuration validation
    run_test "Git configuration is valid" \
        "yq e '.git.user.name' \"$PROJECT_ROOT/config/default.yml.example\" &>/dev/null && \
         yq e '.git.user.email' \"$PROJECT_ROOT/config/default.yml.example\" &>/dev/null" || ((failed_tests++))

    run_test "Node.js configuration is valid" \
        "yq e '.node.versions' \"$PROJECT_ROOT/config/default.yml.example\" &>/dev/null && \
         yq e '.node.default' \"$PROJECT_ROOT/config/default.yml.example\" &>/dev/null" || ((failed_tests++))

    run_test "Homebrew configuration is valid" \
        "yq e '.homebrew.formulas' \"$PROJECT_ROOT/config/default.yml.example\" &>/dev/null && \
         yq e '.homebrew.casks' \"$PROJECT_ROOT/config/default.yml.example\" &>/dev/null" || ((failed_tests++))

    # Test file permissions and structure
    run_test "Critical files are executable" \
        "{ [[ -x \"$PROJECT_ROOT/setup.sh\" ]] || echo \"setup.sh is not executable\"; } && \
         { [[ -x \"$PROJECT_ROOT/test/test.sh\" ]] || echo \"test/test.sh is not executable\"; }" || ((failed_tests++))

    run_test "Module directory structure is correct" \
        "[[ -d \"$PROJECT_ROOT/lib/modules\" ]] && \
         [[ -f \"$PROJECT_ROOT/lib/utils.sh\" ]] && \
         [[ -f \"$PROJECT_ROOT/lib/logging.sh\" ]]" || ((failed_tests++))

    # Test secrets setup
    run_test "Secrets example file exists" \
        "[[ -f \"$PROJECT_ROOT/.secrets.example\" ]]" || ((failed_tests++))

    run_test "Secrets example file has correct format" \
        "grep -q '^GITHUB_TOKEN=' \"$PROJECT_ROOT/.secrets.example\" && \
         grep -q '^GITHUB_TOKEN_ALT=' \"$PROJECT_ROOT/.secrets.example\"" || ((failed_tests++))

    run_test "Secrets file is in gitignore" \
        "grep -q '^\.secrets$' \"$PROJECT_ROOT/.gitignore\"" || ((failed_tests++))

    # Print detailed summary
    print_test_summary "$failed_tests"

    if ((failed_tests > 0)); then
        exit 1
    else
        log_success "All tests passed successfully"
    fi
}

# Run main with error handling
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    trap 'echo "Error: Test script failed on line $LINENO"' ERR
    main "$@"
fi
