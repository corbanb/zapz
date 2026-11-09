#!/usr/bin/env bash

# First-run experience: preview and confirmation, the setup wizard and
# presets, backups, the pinned yq download, and the output layer.

# shellcheck source=helpers.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/helpers.sh"

# A Mac-like sandbox with a small config, for running setup.sh end to end
setup_mac_sandbox() {
    setup_sandbox
    stub uname '[[ "$1" == -m ]] && echo arm64 || echo Darwin'
    stub sw_vers 'echo 27.2'
    stub ssh-keygen 'touch "$HOME/.ssh/id_ed25519" "$HOME/.ssh/id_ed25519.pub"'
    brew_installed jq
    cat > "$SANDBOX/config.yml" << 'EOF'
git:
  user: { name: "Ada", email: "ada@example.com" }
homebrew:
  formulas: ["jq", "ripgrep"]
  casks: ["iterm2"]
macos:
  dock: { autohide: true }
cron:
  update_schedule: { enabled: false }
EOF
}

zapz() {
    "$BASH" "$PROJECT_ROOT/setup.sh" -c "$SANDBOX/config.yml" "$@"
}

# --- preview and confirmation -------------------------------------------

test_dry_run_previews_without_changing_anything() {
    setup_mac_sandbox
    local out
    out=$(zapz --dry-run 2>&1)
    [[ "$out" == *"Here's what zapz will do"* ]] || fail "$out"
    [[ "$out" == *"ripgrep · 1 already installed"* ]] || fail "packages row: $out"
    [[ "$out" == *"iterm2"* && "$out" == *"Dock: auto-hide on"* ]] || fail "$out"
    [[ "$out" == *"Dry run: nothing was changed"* ]] || fail "$out"
    assert_not_contains "$STUB_LOG" "brew install"
    assert_not_contains "$STUB_LOG" "defaults write"
    assert_no_file "$HOME/.gitconfig"
}

test_without_a_terminal_requires_yes() {
    setup_mac_sandbox
    local out status=0
    out=$(ZAPZ_NONINTERACTIVE=1 zapz 2>&1) || status=$?
    assert_eq "$status" 1 "exit status"
    [[ "$out" == *"--yes"* ]] || fail "$out"
    assert_not_contains "$STUB_LOG" "brew install"
}

test_declining_changes_nothing() {
    setup_mac_sandbox
    printf 'n\n' > "$SANDBOX/answers"
    local out
    out=$(ZAPZ_TTY="$SANDBOX/answers" zapz 2>&1)
    [[ "$out" == *"Nothing was changed"* ]] || fail "$out"
    assert_not_contains "$STUB_LOG" "brew install"
}

test_yes_runs_everything_and_summarizes() {
    setup_mac_sandbox
    local out
    out=$(ZAPZ_NONINTERACTIVE=1 zapz --yes 2>&1)
    [[ "$out" == *"[1/8] Command Line Tools"* ]] || fail "no step headers: $out"
    [[ "$out" == *"✓ Done"* ]] || fail "no summary: $out"
    [[ "$out" == *"Full log:"* ]] || fail "no log path: $out"
    assert_contains "$STUB_LOG" "brew install ripgrep"
    assert_contains "$STUB_LOG" "brew install --cask iterm2"
    assert_not_contains "$STUB_LOG" "brew install jq"
    assert_eq "$(git config --global user.name)" "Ada"
    # The password was asked for once, up front, because an app was missing
    assert_count "$STUB_LOG" "sudo -v" 1

    # A second run installs nothing again
    out=$(ZAPZ_NONINTERACTIVE=1 zapz --yes 2>&1)
    assert_count "$STUB_LOG" "brew install ripgrep" 1
    [[ "$out" == *"ripgrep"*"already installed"* ]] || fail "$out"
}

test_failures_are_summarized_and_exit_nonzero() {
    setup_mac_sandbox
    echo ripgrep >> "$STUB_STATE/brew_fail"
    local out status=0
    out=$(ZAPZ_NONINTERACTIVE=1 zapz --yes 2>&1) || status=$?
    assert_eq "$status" 1 "exit status"
    [[ "$out" == *"Finished with 1 problem"* ]] || fail "$out"
    # Later steps still ran
    assert_contains "$STUB_LOG" "brew install --cask iterm2"
}

test_invalid_config_stops_before_changes() {
    setup_mac_sandbox
    echo 'homebrew: [unclosed' > "$SANDBOX/config.yml"
    local out status=0
    out=$(ZAPZ_NONINTERACTIVE=1 zapz --yes 2>&1) || status=$?
    assert_eq "$status" 1 "exit status"
    [[ "$out" == *"Invalid YAML"* ]] || fail "$out"
    assert_not_contains "$STUB_LOG" "brew"
}

# --- wizard and presets ---------------------------------------------------

run_wizard_with() {
    printf '%b' "$1" > "$SANDBOX/answers"
    ZAPZ_TTY="$SANDBOX/answers"
    open_prompt_input
    run_config_wizard "$SANDBOX/out.yml" > /dev/null 2>&1
}

test_wizard_writes_config_from_preset() {
    setup_sandbox; load_zapz
    # name, email, preset 3 (Minimal), no macOS settings, no updates
    run_wizard_with 'Grace Hopper\ngrace@example.com\n3\nn\nn\n'
    local f="$SANDBOX/out.yml"
    assert_eq "$(yq e '.git.user.name' "$f")" "Grace Hopper"
    assert_eq "$(yq e '.git.user.email' "$f")" "grace@example.com"
    assert_eq "$(yq e '.macos' "$f")" "null" "macOS settings removed"
    assert_eq "$(yq e '.cron.update_schedule.enabled' "$f")" "false"
    assert_eq "$(yq e '.homebrew.casks | length' "$f")" "0"
    assert_contains "$f" "Minimal preset"
}

test_wizard_defaults_and_retries_bad_choice() {
    setup_sandbox; load_zapz
    # blank name/email, an invalid choice, then 1 (Essentials), defaults after
    run_wizard_with '\n\n9\n1\n\n\n'
    local f="$SANDBOX/out.yml"
    assert_eq "$(yq e '.git.user' "$f")" "null" "no identity written when left blank"
    assert_eq "$(yq e '.homebrew.casks[0]' "$f")" "visual-studio-code"
    assert_eq "$(yq e '.cron.update_schedule.enabled' "$f")" "true"
    assert_eq "$(yq e '.macos.dock.autohide' "$f")" "true"
}

test_wizard_backs_up_existing_config() {
    setup_sandbox; load_zapz
    echo "mine: true" > "$SANDBOX/out.yml"
    ZAPZ_BACKUP_DIR="$SANDBOX/backups"
    run_wizard_with '\n\n2\n\n\n'
    assert_contains "$SANDBOX/backups/${SANDBOX#/}/out.yml" "mine: true"
}

# Every key a preset uses must be one zapz understands
test_presets_only_use_known_keys() {
    local example="$PROJECT_ROOT/config/default.yml.example" preset known used unknown
    known=$(yq e '.. | path | map(select(tag == "!!str")) | join(".")' "$example" | sort -u)
    for preset in "$PROJECT_ROOT"/config/presets/*.yml; do
        used=$(yq e '.. | path | map(select(tag == "!!str")) | join(".")' "$preset" | sort -u)
        unknown=$(comm -23 <(echo "$used") <(echo "$known"))
        [[ -z "$unknown" ]] || fail "$(basename "$preset") uses unknown keys: $unknown"
    done
}

test_installer_runs_the_wizard() {
    setup_sandbox
    stub uname 'echo Darwin'
    # name, email, Web development, macOS yes, updates yes, don't run setup now
    printf 'Ada\nada@example.com\n2\ny\ny\nn\n' > "$SANDBOX/answers"
    local out
    out=$(ZAPZ_TTY="$SANDBOX/answers" ZAPZ_SOURCE="$PROJECT_ROOT" "$BASH" "$PROJECT_ROOT/install.sh" 2>&1)
    [[ "$out" == *"Saved your config"* ]] || fail "$out"
    [[ "$out" == *"run zapz to preview"* ]] || fail "$out"
    local config="$HOME/.local/share/zapz/config/default.yml"
    assert_eq "$(yq e '.git.user.name' "$config")" "Ada"
    assert_contains "$config" "docker-desktop"
}

# --- safety ---------------------------------------------------------------

test_managed_block_backs_up_and_skips_no_ops() {
    setup_sandbox; load_zapz
    ZAPZ_BACKUP_DIR="$SANDBOX/backups"
    printf 'original\n' > "$HOME/.zshrc"
    write_managed_block "$HOME/.zshrc" demo "export A=1"
    assert_eq "$(cat "$SANDBOX/backups/.zshrc")" "original"

    # Same content again: file isn't rewritten
    touch -t 200001010000 "$HOME/.zshrc"
    write_managed_block "$HOME/.zshrc" demo "export A=1"
    [[ -z "$(find "$HOME/.zshrc" -newer "$SANDBOX/backups/.zshrc")" ]] || fail "unchanged file was rewritten"
}

test_yq_download_rejects_bad_checksum() {
    setup_sandbox; load_zapz
    # Hide the real yq behind an incompatible one, and serve a bogus download
    stub yq 'echo "yq 0.0.0 (python)"'
    stub curl 'while [[ $# -gt 0 ]]; do [[ "$1" == -o ]] && { echo bogus > "$2"; shift; }; shift; done'
    ZAPZ_ROOT="$SANDBOX/root"
    local out status=0
    out=$(ensure_yq 2>&1) || status=$?
    assert_eq "$status" 1 "exit status"
    [[ "$out" == *"checksum"* ]] || fail "$out"
    assert_no_file "$SANDBOX/root/bin/yq"
}

# --- output ---------------------------------------------------------------

test_failed_command_shows_only_its_own_output() {
    setup_sandbox; load_zapz
    ZAPZ_LOG="$SANDBOX/run.log"
    echo "output from an earlier step" > "$ZAPZ_LOG"
    # shellcheck disable=SC2317,SC2329  # called indirectly by run_quiet
    noisy_failure() { printf '###### 45.6%%\rthe real error\n'; return 3; }
    local out status=0
    out=$(run_quiet "demo" noisy_failure 2>&1) || status=$?
    assert_eq "$status" 3 "exit status"
    [[ "$out" == *"the real error"* ]] || fail "$out"
    [[ "$out" != *"earlier step"* && "$out" != *"45.6"* ]] || fail "unrelated output shown: $out"
    assert_contains "$ZAPZ_LOG" "the real error"
}

test_housekeeping_is_not_counted_as_a_change() {
    setup_sandbox; load_zapz
    ZAPZ_LOG="$SANDBOX/run.log"
    run_quiet --housekeeping "refresh" true > /dev/null
    run_quiet "install thing" true > /dev/null
    assert_eq "$ZAPZ_COUNT_CHANGED" 1
}

test_no_color_without_a_terminal() {
    local out
    out=$("$BASH" -c ". '$PROJECT_ROOT/lib/logging.sh'; log_success hi" | od -c)
    [[ "$out" != *"033"* ]] || fail "color codes written to a pipe"
}

section "preview and confirmation"
run_test "--dry-run previews and changes nothing" test_dry_run_previews_without_changing_anything
run_test "without a terminal, --yes is required" test_without_a_terminal_requires_yes
run_test "answering no changes nothing" test_declining_changes_nothing
run_test "--yes runs every step, then summarizes" test_yes_runs_everything_and_summarizes
run_test "failures are summarized and exit non-zero" test_failures_are_summarized_and_exit_nonzero
run_test "an invalid config stops before any change" test_invalid_config_stops_before_changes

section "wizard and presets"
run_test "writes the config from a preset and answers" test_wizard_writes_config_from_preset
run_test "uses defaults and re-asks after a bad choice" test_wizard_defaults_and_retries_bad_choice
run_test "backs up the config it replaces" test_wizard_backs_up_existing_config
run_test "presets only use known config keys" test_presets_only_use_known_keys
run_test "the installer runs the wizard" test_installer_runs_the_wizard

section "safety"
run_test "managed blocks back up files and skip no-ops" test_managed_block_backs_up_and_skips_no_ops
run_test "a yq download with a bad checksum is rejected" test_yq_download_rejects_bad_checksum

section "output"
run_test "a failure shows only that command's output" test_failed_command_shows_only_its_own_output
run_test "housekeeping isn't counted as a change" test_housekeeping_is_not_counted_as_a_change
run_test "no color codes when output isn't a terminal" test_no_color_without_a_terminal

finish_tests
