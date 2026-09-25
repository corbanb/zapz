#!/usr/bin/env bash

# Behavioral tests: run each setup module against a sandboxed HOME with
# stubbed system commands, then check what it changed and what it called.

# shellcheck source=helpers.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/helpers.sh"

# --- config helpers -------------------------------------------------------

test_config_get() {
    setup_sandbox; load_zapz
    use_config << 'EOF'
a: "value"
off: false
empty: ""
EOF
    assert_eq "$(config_get '.a')" "value"
    assert_eq "$(config_get '.off' true)" "false" "false must not become the default"
    assert_eq "$(config_get '.empty' fallback)" "fallback"
    assert_eq "$(config_get '.missing.key' fallback)" "fallback"
    assert_eq "$(config_get '.missing.key')" ""
    assert_eq "$(config_list '.missing')" ""
    config_enabled '.missing' true
    if config_enabled '.off' true; then fail "config_enabled ignored explicit false"; fi
}

test_write_managed_block_is_idempotent() {
    setup_sandbox; load_zapz
    local rc="$HOME/.zshrc"
    printf 'before\n' > "$rc"
    write_managed_block "$rc" demo "export A=1"
    write_managed_block "$rc" demo "export A=2"
    printf 'after\n' >> "$rc"
    write_managed_block "$rc" demo "export A=3"
    assert_count "$rc" "# >>> zapz demo >>>" 1
    assert_not_contains "$rc" "export A=2"
    assert_contains "$rc" "export A=3"
    assert_contains "$rc" "before"
    assert_contains "$rc" "after"
}

test_version_gt() {
    load_zapz
    version_gt 0.10.0 0.9.9
    version_gt v1.0.0 0.9.0
    if version_gt 1.0.0 1.0.0; then fail "equal versions"; fi
    if version_gt 0.9.9 0.10.0; then fail "0.9.9 > 0.10.0"; fi
}

# --- git ------------------------------------------------------------------

test_git_keeps_existing_identity() {
    setup_sandbox; load_zapz
    git config --global user.name "Existing Name"
    git config --global user.email "existing@example.com"
    use_config << 'EOF'
git:
  user: { name: "", email: "" }
EOF
    setup_git
    assert_eq "$(git config --global user.name)" "Existing Name"
    assert_eq "$(git config --global user.email)" "existing@example.com"
}

test_git_applies_config() {
    setup_sandbox; load_zapz
    git config --global alias.co "checkout --quiet"
    use_config << 'EOF'
git:
  user: { name: "Ada", email: "ada@example.com" }
  editor: "code --wait"
  default_branch: "trunk"
  config:
    pull.rebase: "true"
    core.autocrlf: input
EOF
    setup_git
    assert_eq "$(git config --global user.name)" "Ada"
    assert_eq "$(git config --global core.editor)" "code --wait"
    assert_eq "$(git config --global init.defaultBranch)" "trunk"
    assert_eq "$(git config --global pull.rebase)" "true"
    assert_eq "$(git config --global core.autocrlf)" "input"
    assert_eq "$(git config --global alias.co)" "checkout --quiet" "existing alias overwritten"
    assert_eq "$(git config --global alias.st)" "status"
}

test_git_skips_missing_keys() {
    setup_sandbox; load_zapz
    use_config <<< 'git: {}'
    setup_git
    if git config --global core.editor >/dev/null; then fail "core.editor set from a missing key"; fi
}

# --- homebrew -------------------------------------------------------------

HOMEBREW_CONFIG='homebrew:
  taps: ["example/tap"]
  formulas: ["jq", "ripgrep", "broken"]
  casks: ["iterm2", "docker"]'

test_homebrew_installs_missing_packages() {
    setup_sandbox; load_zapz
    brew_installed jq
    brew_installed docker
    use_config <<< "$HOMEBREW_CONFIG"
    setup_homebrew
    assert_contains "$STUB_LOG" "brew install ripgrep"
    assert_contains "$STUB_LOG" "brew install --cask iterm2"
    assert_contains "$STUB_LOG" "brew tap example/tap"
    assert_not_contains "$STUB_LOG" "brew install jq"
    assert_not_contains "$STUB_LOG" "brew install --cask docker"
}

test_homebrew_failure_does_not_abort() {
    setup_sandbox; load_zapz
    use_config <<< "$HOMEBREW_CONFIG"
    echo broken >> "$STUB_STATE/brew_fail"
    local output
    output=$(setup_homebrew 2>&1)
    # Packages after the failing one are still installed
    assert_contains "$STUB_LOG" "brew install --cask iterm2"
    [[ "$output" == *"formula broken"* ]] || fail "failure not reported: $output"
}

test_homebrew_shellenv_added_once() {
    setup_sandbox; load_zapz
    use_config <<< 'homebrew: {}'
    setup_homebrew
    setup_homebrew
    assert_count "$HOME/.zprofile" "brew shellenv)" 1
    assert_count "$HOME/.zprofile" "# >>> zapz homebrew >>>" 1
}

# --- scheduled updates ----------------------------------------------------

assert_valid_plist() {
    python3 -c 'import plistlib, sys; plistlib.load(open(sys.argv[1], "rb"))' "$1" \
        || fail "invalid plist: $1"
}

plist_value() {
    python3 -c '
import plistlib, sys, json
p = plistlib.load(open(sys.argv[1], "rb"))
print(json.dumps(p[sys.argv[2]], sort_keys=True))' "$1" "$2"
}

test_schedule_weekly() {
    setup_sandbox; load_zapz
    use_config << 'EOF'
cron:
  update_schedule: { enabled: true, frequency: weekly, time: "09:30", days: ["MONDAY", "friday"] }
EOF
    setup_scheduled_updates
    local plist
    plist=$(launch_agent_path)
    assert_valid_plist "$plist"
    assert_eq "$(plist_value "$plist" StartCalendarInterval)" \
        '[{"Hour": 9, "Minute": 30, "Weekday": 1}, {"Hour": 9, "Minute": 30, "Weekday": 5}]'
    assert_eq "$(plist_value "$plist" ProgramArguments)" "[\"/bin/bash\", \"$PROJECT_ROOT/lib/maintenance.sh\"]"
    assert_contains "$STUB_LOG" "launchctl bootstrap gui/"
}

test_schedule_daily_and_monthly() {
    setup_sandbox; load_zapz
    use_config <<< 'cron: { update_schedule: { enabled: true, frequency: daily, time: "7:05" } }'
    setup_scheduled_updates
    assert_eq "$(plist_value "$(launch_agent_path)" StartCalendarInterval)" '[{"Hour": 7, "Minute": 5}]'

    use_config <<< 'cron: { update_schedule: { enabled: true, frequency: monthly, time: "23:59" } }'
    setup_scheduled_updates
    assert_eq "$(plist_value "$(launch_agent_path)" StartCalendarInterval)" '[{"Day": 1, "Hour": 23, "Minute": 59}]'
}

test_schedule_disabled_removes_agent() {
    setup_sandbox; load_zapz
    use_config <<< 'cron: { update_schedule: { enabled: true, frequency: daily, time: "09:00" } }'
    setup_scheduled_updates
    assert_file "$(launch_agent_path)"
    use_config <<< 'cron: { update_schedule: { enabled: false } }'
    setup_scheduled_updates
    assert_no_file "$(launch_agent_path)"
    assert_contains "$STUB_LOG" "launchctl bootout"
}

test_schedule_rejects_bad_input() {
    setup_sandbox; load_zapz
    use_config <<< 'cron: { update_schedule: { enabled: true, frequency: daily, time: "25:00" } }'
    if (setup_scheduled_updates) >/dev/null 2>&1; then fail "accepted time 25:00"; fi
    use_config <<< 'cron: { update_schedule: { enabled: true, frequency: weekly, time: "09:00", days: ["Funday"] } }'
    if (setup_scheduled_updates) >/dev/null 2>&1; then fail "accepted day Funday"; fi
    use_config <<< 'cron: { update_schedule: { enabled: true, frequency: hourly, time: "09:00" } }'
    if (setup_scheduled_updates) >/dev/null 2>&1; then fail "accepted frequency hourly"; fi
    assert_no_file "$(launch_agent_path)"
}

# --- macOS preferences ----------------------------------------------------

test_macos_writes_configured_defaults_only() {
    setup_sandbox; load_zapz
    use_config << 'EOF'
macos:
  dock: { autohide: true, magnification: false }
  finder: { show_path_bar: true }
EOF
    setup_macos_preferences
    assert_contains "$STUB_LOG" "defaults write com.apple.dock autohide -bool true"
    assert_contains "$STUB_LOG" "defaults write com.apple.dock magnification -bool false"
    assert_contains "$STUB_LOG" "defaults write com.apple.finder ShowPathbar -bool true"
    assert_not_contains "$STUB_LOG" "KeyRepeat"
    assert_not_contains "$STUB_LOG" "null"
    assert_not_contains "$STUB_LOG" "sudo"
}

test_macos_developer_mode_opt_in() {
    setup_sandbox; load_zapz
    use_config <<< 'macos: { developer_mode: true, keyboard: { key_repeat: 2 } }'
    setup_macos_preferences
    assert_contains "$STUB_LOG" "sudo /usr/sbin/DevToolsSecurity -enable"
    assert_contains "$STUB_LOG" "defaults write NSGlobalDomain KeyRepeat -int 2"
}

# --- ssh ------------------------------------------------------------------

test_ssh_adds_github_host_to_existing_config() {
    setup_sandbox; load_zapz
    use_config <<< 'git: {}'
    mkdir -p "$HOME/.ssh"
    touch "$HOME/.ssh/id_ed25519" "$HOME/.ssh/id_ed25519.pub"
    printf 'Host work\n    HostName work.example.com\n' > "$HOME/.ssh/config"
    setup_ssh
    setup_ssh
    assert_count "$HOME/.ssh/config" "Host github.com" 1
    assert_contains "$HOME/.ssh/config" "Host work"
    assert_not_contains "$STUB_LOG" "ssh-keygen"
}

test_ssh_generates_key_with_passphrase_prompt() {
    setup_sandbox; load_zapz
    stub ssh-keygen 'touch "$HOME/.ssh/id_ed25519" "$HOME/.ssh/id_ed25519.pub"'
    use_config <<< 'git: { user: { email: "ada@example.com" } }'
    setup_ssh
    assert_contains "$STUB_LOG" "ssh-keygen -t ed25519 -C ada@example.com"
    assert_not_contains "$STUB_LOG" "-N"
    assert_contains "$HOME/.ssh/config" "Host github.com"
}

# --- node -----------------------------------------------------------------

# A fake nvm: records calls; versions in $STUB_STATE/nvm count as installed
fake_nvm() {
    mkdir -p "$HOME/.nvm"
    cat > "$HOME/.nvm/nvm.sh" << 'EOF'
nvm() {
    echo "nvm $*" >> "$STUB_LOG"
    case "$1" in
        version) grep -qx "$2" "$STUB_STATE/nvm" 2>/dev/null && echo "v0.0.0" || echo "N/A" ;;
        install) echo "$2" >> "$STUB_STATE/nvm" ;;
    esac
}
EOF
    stub npm '[[ "$1" == list ]] && exit 1; exit 0'
}

test_node_rerun_with_existing_nvm() {
    setup_sandbox; load_zapz
    fake_nvm
    echo "lts/jod" > "$STUB_STATE/nvm"
    use_config << 'EOF'
node:
  versions: ["lts/krypton", "lts/jod"]
  default: "lts/krypton"
  global_packages: ["pnpm"]
EOF
    setup_node
    assert_contains "$STUB_LOG" "nvm install lts/krypton"
    assert_not_contains "$STUB_LOG" "nvm install lts/jod"
    assert_contains "$STUB_LOG" "nvm alias default lts/krypton"
    assert_contains "$STUB_LOG" "npm install -g pnpm"
    assert_not_contains "$STUB_LOG" "curl"
    assert_count "$HOME/.zshrc" "zapz nvm >>>" 1
    setup_node
    assert_count "$HOME/.zshrc" "zapz nvm >>>" 1
}

# --- update notice (sourced from users' shells) ---------------------------

prepare_update_cache() {
    export ZAPZ_HOME="$PROJECT_ROOT"
    mkdir -p "$HOME/.cache/zapz"
    echo "$1" > "$HOME/.cache/zapz/latest_version"
    stub curl 'exit 1'
}

test_update_notice_when_newer() {
    setup_sandbox
    prepare_update_cache "99.0.0"
    local out
    out=$(bash -c '. "$ZAPZ_HOME/lib/check_update.sh"')
    [[ "$out" == *"zapz 99.0.0 is available"* ]] || fail "no notice: $out"
    assert_not_contains "$STUB_LOG" "curl"
}

test_update_notice_silent_when_current_or_disabled() {
    setup_sandbox
    prepare_update_cache "0.0.1"
    assert_eq "$(bash -c '. "$ZAPZ_HOME/lib/check_update.sh"')" ""
    prepare_update_cache "99.0.0"
    assert_eq "$(ZAPZ_DISABLE_UPDATE_CHECK=1 bash -c '. "$ZAPZ_HOME/lib/check_update.sh"')" ""
}

test_update_notice_in_zsh_without_leaks() {
    command -v zsh >/dev/null || { echo "zsh not installed; skipped"; return 0; }
    setup_sandbox
    prepare_update_cache "99.0.0"
    local out
    out=$(zsh -f -c 'current=mine; . "$ZAPZ_HOME/lib/check_update.sh"; echo "current=$current"; if typeset -f _zapz_update_notice >/dev/null; then echo leaked-function; fi')
    [[ "$out" == *"zapz 99.0.0 is available"* ]] || fail "no notice in zsh: $out"
    [[ "$out" == *"current=mine"* ]] || fail "clobbered caller variable: $out"
    [[ "$out" != *"leaked-function"* ]] || fail "helper function left defined"
}

test_update_notice_refreshes_stale_cache_in_background() {
    setup_sandbox
    export ZAPZ_HOME="$PROJECT_ROOT"
    stub curl 'echo "{\"tag_name\": \"v42.0.0\"}"'
    bash -c '. "$ZAPZ_HOME/lib/check_update.sh"'
    local i
    for i in 1 2 3 4 5 6 7 8 9 10; do
        [[ "$(cat "$HOME/.cache/zapz/latest_version" 2>/dev/null)" == "42.0.0" ]] && return 0
        sleep 0.2
    done
    fail "cache not refreshed: $(cat "$HOME/.cache/zapz/latest_version")"
}

# --- setup.sh CLI ---------------------------------------------------------

test_cli_arguments() {
    setup_sandbox
    local out status
    "$PROJECT_ROOT/setup.sh" --version | grep -q "zapz version"
    "$PROJECT_ROOT/setup.sh" --help | grep -q "Usage: zapz"

    status=0; out=$("$PROJECT_ROOT/setup.sh" --bogus 2>&1) || status=$?
    assert_eq "$status" 1 "exit status for unknown option"
    [[ "$out" == *"Unknown option: --bogus"* ]] || fail "$out"

    status=0; out=$("$PROJECT_ROOT/setup.sh" --config 2>&1) || status=$?
    assert_eq "$status" 1 "exit status for missing option value"
    [[ "$out" == *"requires a value"* ]] || fail "$out"
}

test_cli_through_symlink() {
    setup_sandbox
    mkdir -p "$HOME/.local/bin"
    ln -s "$PROJECT_ROOT/setup.sh" "$HOME/.local/bin/zapz"
    "$HOME/.local/bin/zapz" --version | grep -q "zapz version"
}

# --- maintenance script (run by launchd) ----------------------------------

test_maintenance_runs_updates() {
    setup_sandbox
    stub mas
    "$PROJECT_ROOT/lib/maintenance.sh" > /dev/null
    assert_contains "$STUB_LOG" "brew update"
    assert_contains "$STUB_LOG" "brew upgrade"
    assert_contains "$STUB_LOG" "mas upgrade"
}

section "config helpers"
run_test "config_get handles missing, empty and false values" test_config_get
run_test "write_managed_block replaces instead of appending" test_write_managed_block_is_idempotent
run_test "version_gt compares numerically" test_version_gt

section "git"
run_test "empty name/email keep the existing identity" test_git_keeps_existing_identity
run_test "applies user, editor, branch and git.config options" test_git_applies_config
run_test "missing keys are not written as null" test_git_skips_missing_keys

section "homebrew"
run_test "installs only missing taps, formulas and casks" test_homebrew_installs_missing_packages
run_test "a failing package doesn't abort setup" test_homebrew_failure_does_not_abort
run_test "shellenv is added to ~/.zprofile once" test_homebrew_shellenv_added_once

section "scheduled updates"
run_test "weekly schedule writes a valid LaunchAgent" test_schedule_weekly
run_test "daily and monthly schedules" test_schedule_daily_and_monthly
run_test "disabling removes the LaunchAgent" test_schedule_disabled_removes_agent
run_test "invalid time, day or frequency is rejected" test_schedule_rejects_bad_input

section "macOS preferences"
run_test "writes only configured settings" test_macos_writes_configured_defaults_only
run_test "developer mode is opt-in" test_macos_developer_mode_opt_in

section "ssh"
run_test "adds github.com to an existing SSH config once" test_ssh_adds_github_host_to_existing_config
run_test "generates a key without an empty passphrase" test_ssh_generates_key_with_passphrase_prompt

section "node"
run_test "re-runs with nvm already installed" test_node_rerun_with_existing_nvm

section "update notice"
run_test "shows a notice when a newer release is cached" test_update_notice_when_newer
run_test "silent when current or disabled" test_update_notice_silent_when_current_or_disabled
run_test "works in zsh without leaking variables" test_update_notice_in_zsh_without_leaks
run_test "refreshes a stale cache in the background" test_update_notice_refreshes_stale_cache_in_background

section "setup.sh"
run_test "argument handling" test_cli_arguments
run_test "works when run through a symlink" test_cli_through_symlink
run_test "maintenance script runs updates" test_maintenance_runs_updates

finish_tests
