#!/usr/bin/env bash

# Static checks: syntax, portability, config shape and config loading.

# shellcheck source=helpers.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/helpers.sh"

EXAMPLE_CONFIG="$PROJECT_ROOT/config/default.yml.example"

shipped_scripts() {
    printf '%s\n' "$PROJECT_ROOT/setup.sh" "$PROJECT_ROOT/install.sh" \
        "$PROJECT_ROOT"/lib/*.sh "$PROJECT_ROOT"/lib/modules/*.sh
}

test_syntax() {
    local file
    while IFS= read -r file; do
        bash -n "$file" || fail "syntax error in $file"
    done < <(shipped_scripts; ls "$PROJECT_ROOT"/test/*.sh "$PROJECT_ROOT"/scripts/*.sh)
}

# macOS ships bash 3.2; these need bash 4+
test_no_bash4_features() {
    local hits
    hits=$(shipped_scripts | xargs grep -nE '\$\{[A-Za-z_]+(,,|\^\^)|declare -A|local -A|mapfile|readarray|&>>|\|&' || true)
    [[ -z "$hits" ]] || fail "bash 4+ syntax found:
$hits"
}

test_executable_bits() {
    local file mode
    for file in setup.sh install.sh lib/maintenance.sh test/run_tests.sh; do
        mode=$(git -C "$PROJECT_ROOT" ls-files -s "$file" | awk '{print $1}')
        assert_eq "$mode" "100755" "git file mode of $file"
    done
}

test_every_module_defines_its_entry_point() {
    local pair
    for pair in xcode:install_xcode_tools homebrew:setup_homebrew git:setup_git ssh:setup_ssh \
            node:setup_node macos:setup_macos_preferences schedule:setup_scheduled_updates; do
        grep -q "^${pair#*:}()" "$PROJECT_ROOT/lib/modules/${pair%%:*}.sh" \
            || fail "${pair%%:*}.sh does not define ${pair#*:}"
        grep -q "${pair#*:}$" "$PROJECT_ROOT/setup.sh" || fail "setup.sh never calls ${pair#*:}"
    done
}

test_example_config_shape() {
    yq e '.' "$EXAMPLE_CONFIG" > /dev/null
    local path
    for path in .homebrew.formulas .homebrew.casks .node.versions; do
        [[ "$(yq e "$path | length" "$EXAMPLE_CONFIG")" -gt 0 ]] || fail "$path is empty"
    done
    [[ -n "$(yq e '.node.default // ""' "$EXAMPLE_CONFIG")" ]] || fail ".node.default is missing"
    assert_eq "$(yq e '.cron.update_schedule.enabled | tag' "$EXAMPLE_CONFIG")" "!!bool"
}

test_config_created_from_example() {
    setup_sandbox; load_zapz
    cp "$EXAMPLE_CONFIG" "$SANDBOX/default.yml.example"
    GIST_URL='' CUSTOM_CONFIG='' DEFAULT_CONFIG="$SANDBOX/default.yml"
    load_configuration > /dev/null
    assert_file "$SANDBOX/default.yml"
    assert_eq "$CONFIG_FILE" "$SANDBOX/default.yml"
}

test_custom_config_used() {
    setup_sandbox; load_zapz
    GIST_URL='' CUSTOM_CONFIG="$EXAMPLE_CONFIG" DEFAULT_CONFIG=/nonexistent
    load_configuration
    assert_eq "$CONFIG_FILE" "$EXAMPLE_CONFIG"
}

test_missing_custom_config_fails() {
    setup_sandbox; load_zapz
    GIST_URL='' CUSTOM_CONFIG=/nonexistent/config.yml
    if (load_configuration) 2>/dev/null; then fail "missing config accepted"; fi
}

test_gist_requires_https() {
    setup_sandbox; load_zapz
    stub curl
    GIST_URL='http://gist.githubusercontent.com/x/raw/config.yml' CUSTOM_CONFIG=''
    if (load_configuration) 2>/dev/null; then fail "http gist accepted"; fi
    assert_not_contains "$STUB_LOG" "curl"
}

test_shellcheck() {
    if ! command -v shellcheck >/dev/null; then
        echo "shellcheck not installed; skipped"
        return 0
    fi
    (cd "$PROJECT_ROOT" && shellcheck -x setup.sh install.sh lib/*.sh lib/modules/*.sh test/*.sh scripts/*.sh)
}

if ! is_compatible_yq_available=$(yq --version 2>&1) || [[ "$is_compatible_yq_available" != *mikefarah* ]]; then
    echo "These tests need mikefarah/yq (brew install yq)" >&2
    exit 1
fi

section "scripts"
run_test "all scripts parse" test_syntax
run_test "no bash 4+ syntax (macOS ships bash 3.2)" test_no_bash4_features
run_test "entry scripts are committed as executable" test_executable_bits
run_test "every module defines and is wired to its entry point" test_every_module_defines_its_entry_point
run_test "shellcheck passes" test_shellcheck

section "configuration"
run_test "example config has the expected shape" test_example_config_shape
run_test "default config is created from the example" test_config_created_from_example
run_test "custom config path is used" test_custom_config_used
run_test "missing custom config fails" test_missing_custom_config_fails
run_test "gist URLs must use https" test_gist_requires_https

finish_tests
