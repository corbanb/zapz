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
        "$BASH" -n "$file" || fail "syntax error in $file"
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
    for file in setup.sh install.sh lib/askpass.sh lib/maintenance.sh test/run_tests.sh scripts/release.sh; do
        mode=$(git -C "$PROJECT_ROOT" ls-files -s "$file" | awk '{print $1}')
        assert_eq "$mode" "100755" "git file mode of $file"
    done
}

test_every_module_defines_its_entry_point() {
    local pair
    for pair in xcode:install_xcode_tools security:setup_security homebrew:setup_homebrew \
            git:setup_git ssh:setup_ssh languages:setup_languages node:setup_node \
            terminal:setup_terminal_shell appstore:setup_app_store macos:setup_macos_preferences \
            schedule:setup_scheduled_updates; do
        grep -q "^${pair#*:}()" "$PROJECT_ROOT/lib/modules/${pair%%:*}.sh" \
            || fail "${pair%%:*}.sh does not define ${pair#*:}"
        grep -qw "${pair#*:}" "$PROJECT_ROOT/setup.sh" || fail "setup.sh never runs ${pair#*:}"
    done
}

test_example_config_shape() {
    yq e '.' "$EXAMPLE_CONFIG" > /dev/null
    local path
    for path in .homebrew.formulas .homebrew.casks .languages.tools .checklist; do
        [[ "$(yq e "$path | length" "$EXAMPLE_CONFIG")" -gt 0 ]] || fail "$path is empty"
    done
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

# scripts/release.sh: the file edits it makes, without git or the network
release_fn() {
    # shellcheck source=/dev/null
    ( source "$PROJECT_ROOT/scripts/release.sh"; "$@" )
}

test_release_promotes_unreleased() {
    local log out
    log=$(mktemp)
    printf '# Changelog\n\n## [Unreleased]\n\n### Fixed\n- A thing.\n\n## [0.3.0] - 2026-11-09\n\n- Old.\n' > "$log"
    out=$(release_fn promote_changelog "$log" 0.3.1 2026-11-10)
    assert_eq "$(printf '%s\n' "$out" | grep -c '^## \[Unreleased\]$')" "1" "one Unreleased heading"
    printf '%s\n' "$out" | grep -q '^## \[0.3.1\] - 2026-11-10$' || fail "no 0.3.1 heading"
    assert_eq "$(release_fn changelog_section <(printf '%s\n' "$out") 0.3.1 | grep -c 'A thing')" "1" "entry moved under 0.3.1"
    assert_eq "$(release_fn changelog_section <(printf '%s\n' "$out") Unreleased | grep -c '[^[:space:]]')" "0" "Unreleased left empty"
    rm -f "$log"
}

test_release_refuses_empty_unreleased() {
    local log
    log=$(mktemp)
    printf '## [Unreleased]\n\n## [0.3.0] - 2026-11-09\n- Old.\n' > "$log"
    if release_fn promote_changelog "$log" 0.3.1 2026-11-10 >/dev/null 2>&1; then
        fail "accepted an empty Unreleased section"
    fi
    printf '## [0.3.0] - 2026-11-09\n- Old.\n' > "$log"
    if release_fn promote_changelog "$log" 0.3.1 2026-11-10 >/dev/null 2>&1; then
        fail "accepted a changelog without Unreleased"
    fi
    rm -f "$log"
}

test_release_bumps_version_file() {
    assert_eq "$(release_fn bump_version_file "$PROJECT_ROOT/lib/version.sh" 9.8.7 | release_fn read_version)" "9.8.7" "bumped version"
    assert_eq "$(release_fn bump_version_file "$PROJECT_ROOT/lib/version.sh" 9.8.7 | grep -c ZAPZ_MIN_MACOS_VERSION)" "1" "other lines kept"
}

test_release_validates_version() {
    release_fn is_semver 0.3.1 || fail "rejected 0.3.1"
    if release_fn is_semver 0.3; then fail "accepted 0.3"; fi
    if release_fn is_semver v0.3.1; then fail "accepted v0.3.1 (main strips the v)"; fi
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

section "release script"
run_test "moves Unreleased changes under the new version" test_release_promotes_unreleased
run_test "refuses an empty or missing Unreleased section" test_release_refuses_empty_unreleased
run_test "bumps only ZAPZ_VERSION" test_release_bumps_version_file
run_test "accepts only X.Y.Z versions" test_release_validates_version

finish_tests
