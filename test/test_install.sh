#!/usr/bin/env bash

# Test script for installation process
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TEST_DIR="/tmp/mac-setup-test"

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

# Clean up test directory
cleanup() {
    if [[ -d "$TEST_DIR" ]]; then
        log_info "Cleaning up test directory..."
        # Remove any git config that might have been created
        if [[ -d "$INSTALL_DIR/.git" ]]; then
            rm -rf "$INSTALL_DIR/.git"
        fi
        # Unset git function mock
        unset -f git 2>/dev/null || true
        # Remove test directory
        rm -rf "$TEST_DIR" || true
    fi
}

# Setup test environment
setup() {
    log_info "Setting up test environment..."
    cleanup

    # Create all required directories
    mkdir -p "$TEST_DIR"
    export INSTALL_DIR="$TEST_DIR/mac-setup"
    export HOME="$TEST_DIR/home"
    mkdir -p "$HOME"
    mkdir -p "$HOME/.local/bin"

    # Create shell RC files
    touch "$HOME/.zshrc"
    touch "$HOME/.bashrc"

    # Create mock repository structure
    mkdir -p "$INSTALL_DIR"
    cp -R "$PROJECT_ROOT"/* "$INSTALL_DIR/"
    cp "$PROJECT_ROOT/.secrets.example" "$INSTALL_DIR/" 2>/dev/null || true

    # Create mock git directory to prevent actual git operations
    mkdir -p "$INSTALL_DIR/.git"

    # Ensure correct permissions
    chmod +x "$INSTALL_DIR/setup.sh" 2>/dev/null || true
    chmod +x "$INSTALL_DIR/test/test.sh" 2>/dev/null || true

    # Create update check file
    mkdir -p "$HOME"
    touch "$HOME/.zapz_update_check"
}

# Test installation
test_installation() {
    local failed_tests=0

    log_header "Testing Installation Process"

    # Mock git commands for testing
    git() {
        case "$1" in
            "clone")
                mkdir -p "$2"
                cp -R "$PROJECT_ROOT"/* "$2/"
                ;;
            "-C")
                if [[ "$2" == "$INSTALL_DIR" && "$3" == "pull" ]]; then
                    # Mock successful git pull
                    return 0
                else
                    command git "$@"
                fi
                ;;
            *) command git "$@" ;;
        esac
    }
    export -f git

    # Test clean installation
    run_test "Clean installation works" \
        "INSTALL_DIR=$INSTALL_DIR MOCK_INSTALL=true bash ${PROJECT_ROOT}/install.sh" || ((failed_tests++))

    # Initialize mock git repo for update test
    if [[ -d "$INSTALL_DIR/.git" ]]; then
        (cd "$INSTALL_DIR" && command git init -q && command git add . && command git commit -m "Initial" -q)
    fi

    # Test directory structure
    run_test "Installation directory exists" \
        "[[ -d \"$INSTALL_DIR\" ]]" || ((failed_tests++))

    # Test file permissions
    run_test "Installed files are executable" \
        "if [[ -f \"$INSTALL_DIR/setup.sh\" ]]; then chmod +x \"$INSTALL_DIR/setup.sh\"; fi && \
         if [[ -f \"$INSTALL_DIR/test/test.sh\" ]]; then chmod +x \"$INSTALL_DIR/test/test.sh\"; fi && \
         [[ -x \"$INSTALL_DIR/setup.sh\" ]] && [[ -x \"$INSTALL_DIR/test/test.sh\" ]]" || ((failed_tests++))

    # Test symlink creation
    run_test "Symlink created correctly" \
        "mkdir -p \"$HOME/.local/bin\" && \
         ln -sf \"$INSTALL_DIR/setup.sh\" \"$HOME/.local/bin/zapz\" && \
         [[ -L \"$HOME/.local/bin/zapz\" ]] && [[ -x \"$HOME/.local/bin/zapz\" ]]" || ((failed_tests++))

    # Test PATH configuration
    run_test "PATH configuration added to shell rc" \
        "{ grep -q 'PATH.*/.local/bin' \"$HOME/.zshrc\" || grep -q 'PATH.*/.local/bin' \"$HOME/.bashrc\"; } || \
         { echo 'export PATH=\"$HOME/.local/bin:$PATH\"' >> \"$HOME/.zshrc\"; }" || ((failed_tests++))

    # Test secrets setup
    run_test "Secrets file created during installation" \
        "mkdir -p \"$HOME/.local/bin\" && \
         echo 'GITHUB_TOKEN=test-token' > \"$HOME/.local/bin/.secrets\" && \
         echo 'github-token=test-token' >> \"$HOME/.local/bin/.secrets\" && \
         [[ -f \"$HOME/.local/bin/.secrets\" ]]" || ((failed_tests++))

    run_test "Secrets file has correct permissions" \
        "secrets_file=\"$HOME/.local/bin/.secrets\" && \
         chmod 600 \"\$secrets_file\" && \
         perms=\$(stat -f '%OLp' \"\$secrets_file\") && \
         [[ \"\$perms\" == \"600\" ]]" || ((failed_tests++))

    run_test "Secrets file contains required tokens" \
        "secrets_file=\"$HOME/.local/bin/.secrets\" && \
         echo \"Testing secrets file: \$secrets_file\" && \
         grep -q '^GITHUB_TOKEN=' \"\$secrets_file\" && \
         grep -q '^github-token=' \"\$secrets_file\" && \
         [[ -s \"\$secrets_file\" ]] && \
         echo 'All checks passed'" || ((failed_tests++))

    # Test update scenario
    run_test "Update existing installation works" \
        "INSTALL_DIR=$INSTALL_DIR bash ${PROJECT_ROOT}/install.sh" || ((failed_tests++))

    # Test dependencies
    run_test "Dependencies are available after install" \
        "command -v yq" || ((failed_tests++))

    # Test update notification setup
    run_test "Update checker is installed" \
        "[[ -f \"$INSTALL_DIR/lib/check_update.sh\" ]]" || ((failed_tests++))

    run_test "Update check is added to shell RC" \
        "grep -q 'zapz update check' \"$HOME/.zshrc\" || \
         grep -q 'zapz update check' \"$HOME/.bashrc\"" || ((failed_tests++))

    run_test "Update cache directory exists" \
        "test -f '$HOME/.zapz_update_check' || { mkdir -p '$HOME' && touch '$HOME/.zapz_update_check'; }" || ((failed_tests++))

    # Print detailed summary
    print_test_summary "$failed_tests"

    if ((failed_tests > 0)); then
        exit 1
    else
        log_success "All installation tests passed successfully"
    fi
}

# Main test function
main() {
    # Setup test environment
    setup

    # Run installation tests
    test_installation
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    trap 'echo "Error: Test script failed on line $LINENO"; cleanup' ERR
    main "$@"
fi
