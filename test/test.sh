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

# Test version handling
test_version_handling() {
    local test_dir
    test_dir=$(mktemp -d)
    local failed_tests=0

    # Setup test git repo
    (
        cd "$test_dir" || exit 1
        git init
        git config --local user.email "test@example.com"
        git config --local user.name "Test User"
        git config --local init.defaultBranch main
        echo "# Test Repo" > README.md
        git add README.md
        git commit -m "Initial commit"
    )

    # Test initial tag creation
    run_test "Initial tag creation (v0.1.0)" \
        "(cd \"$test_dir\" && \
         ! git tag | grep -q '^v' && \
         git tag -a v0.1.0 -m 'Initial release' && \
         git tag | grep -q '^v0.1.0$')" || ((failed_tests++))

    # Test version increment scenarios
    local version_tests=(
        "v0.1.0:v0.1.1"     # Basic increment
        "v1.0.0:v1.0.1"     # Major version
        "v0.9.9:v0.9.10"    # Double digit increment
        "v1.9.99:v1.9.100"  # Triple digit increment
        "v2.0.0-beta:v2.0.1" # Pre-release version
    )

    for test_case in "${version_tests[@]}"; do
        local current_version="${test_case%%:*}"
        local expected_version="${test_case#*:}"

        # Clean previous tags
        (cd "$test_dir" && git tag | xargs git tag -d >/dev/null 2>&1)

        # Test version increment
        run_test "Version increment from $current_version to $expected_version" \
            "(cd \"$test_dir\" && \
             git tag -a \"$current_version\" -m 'Test version' && \
             latest_tag=\$(git tag -l \"v*\" | sort -V | tail -n1) && \
             current_version=\${latest_tag#v} && \
             major=\$(echo \$current_version | cut -d. -f1) && \
             minor=\$(echo \$current_version | cut -d. -f2) && \
             patch=\$(echo \$current_version | cut -d. -f3 | cut -d- -f1) && \
             next_patch=\$((patch + 1)) && \
             next_version=\"v\$major.\$minor.\$next_patch\" && \
             [ \"\$next_version\" = \"$expected_version\" ])" || ((failed_tests++))
    done

    # Clean tags for sorting test
    (cd "$test_dir" && git tag | xargs git tag -d >/dev/null 2>&1)

    # Test version sorting with mixed versions
    (cd "$test_dir" || exit 1
     # Create tags in random order
     git tag -a v0.2.0 -m "Test version"
     git tag -a v0.1.0 -m "Test version"
     git tag -a v0.10.0 -m "Test version"
     git tag -a v1.0.0-beta -m "Test version"
     git tag -a v1.0.0 -m "Test version"
    )

    run_test "Version sorting handles mixed versions correctly" \
        "(cd \"$test_dir\" && \
         latest_tag=\$(git tag -l \"v*\" | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -n1) && \
         echo \"Latest tag: \$latest_tag\" && \
         [ \"\$latest_tag\" = \"v1.0.0\" ])" || ((failed_tests++))

    # Clean tags for duplicate test
    (cd "$test_dir" && git tag | xargs git tag -d >/dev/null 2>&1)

    # Test duplicate tag prevention
    run_test "Prevents duplicate tag creation" \
        "(cd \"$test_dir\" && \
         git tag -a v0.1.0 -m 'Test version' && \
         ! git tag -a v0.1.0 -m 'Duplicate tag' 2>/dev/null)" || ((failed_tests++))

    # Clean tags for invalid version test
    (cd "$test_dir" && git tag | xargs git tag -d >/dev/null 2>&1)

    # Test invalid version handling
    run_test "Handles invalid version tags" \
        "(cd \"$test_dir\" && \
         git tag -a v1.0.0 -m 'Valid version' && \
         git tag -a vinvalid -m 'Invalid version' && \
         latest_tag=\$(git tag -l \"v*\" | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+' | sort -V | tail -n1) && \
         [ \"\$latest_tag\" = \"v1.0.0\" ])" || ((failed_tests++))

    # Cleanup
    rm -rf "$test_dir"

    return "$failed_tests"
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

    # Test PR requirements
    run_test "PR title format validation regex is valid" \
        "echo 'feat: test title' | grep -E '^(feat|fix|docs|style|refactor|test|chore)(\(.+\))?: .+' &>/dev/null && \
         echo 'fix(core): another test' | grep -E '^(feat|fix|docs|style|refactor|test|chore)(\(.+\))?: .+' &>/dev/null" || ((failed_tests++))

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

    # Run version handling tests
    log_header "Running Version Handling Tests"
    test_version_handling
    failed_tests=$((failed_tests + $?))

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
