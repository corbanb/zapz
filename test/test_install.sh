#!/usr/bin/env bash

# Installation tests: run install.sh against a sandboxed HOME, copying this
# checkout (ZAPZ_SOURCE) instead of cloning, and check what it produced.

# shellcheck source=helpers.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/helpers.sh"

# Run install.sh as if on macOS
run_install() {
    stub uname 'echo Darwin'
    ZAPZ_SOURCE="$PROJECT_ROOT" bash "$PROJECT_ROOT/install.sh"
}

test_fresh_install() {
    setup_sandbox
    run_install > /dev/null
    local zapz_home="$HOME/.local/share/zapz"
    assert_file "$zapz_home/setup.sh"
    assert_file "$zapz_home/config/default.yml"
    [[ -L "$HOME/.local/bin/zapz" ]] || fail "zapz symlink not created"
    "$HOME/.local/bin/zapz" --version | grep -q "zapz version"
    assert_contains "$HOME/.zshrc" "export ZAPZ_HOME=\"$zapz_home\""
    assert_contains "$HOME/.zshrc" 'lib/check_update.sh'
    assert_no_file "$HOME/.local/bin/.secrets"
}

test_reinstall_is_idempotent() {
    setup_sandbox
    run_install > /dev/null
    echo "custom: true" >> "$HOME/.local/share/zapz/config/default.yml"
    run_install > /dev/null
    assert_count "$HOME/.zshrc" "# >>> zapz cli >>>" 1
    assert_contains "$HOME/.local/share/zapz/config/default.yml" "custom: true"
}

test_shell_rc_sources_cleanly() {
    setup_sandbox
    run_install > /dev/null
    mkdir -p "$HOME/.cache/zapz"
    echo "0.0.1" > "$HOME/.cache/zapz/latest_version"
    # Sourcing the rc must succeed, put zapz on PATH and print nothing
    local out
    out=$(PATH="/usr/bin:/bin" bash -c '. "$HOME/.zshrc" && command -v zapz')
    assert_eq "$out" "$HOME/.local/bin/zapz"
}

test_bash_users_get_bash_profile() {
    setup_sandbox
    export SHELL=/bin/bash
    run_install > /dev/null
    assert_contains "$HOME/.bash_profile" "# >>> zapz cli >>>"
    assert_no_file "$HOME/.zshrc"
}

test_refuses_non_zapz_directory() {
    setup_sandbox
    stub uname 'echo Darwin'
    mkdir -p "$HOME/.local/share/zapz"
    touch "$HOME/.local/share/zapz/something"
    if ZAPZ_REPO=/nonexistent bash "$PROJECT_ROOT/install.sh" >/dev/null 2>&1; then
        fail "installed over an unrelated directory"
    fi
}

test_refuses_non_macos() {
    setup_sandbox
    stub uname 'echo Linux'
    local out
    if out=$(ZAPZ_SOURCE="$PROJECT_ROOT" bash "$PROJECT_ROOT/install.sh" 2>&1); then
        fail "installed on Linux"
    fi
    [[ "$out" == *"only works on macOS"* ]] || fail "$out"
}

section "install.sh"
run_test "fresh install creates checkout, config, command and rc block" test_fresh_install
run_test "reinstall keeps config and doesn't duplicate rc changes" test_reinstall_is_idempotent
run_test "installed rc block sources cleanly" test_shell_rc_sources_cleanly
run_test "bash users get ~/.bash_profile" test_bash_users_get_bash_profile
run_test "refuses to install over an unrelated directory" test_refuses_non_zapz_directory
run_test "refuses to run outside macOS" test_refuses_non_macos

finish_tests
