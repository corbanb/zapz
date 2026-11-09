#!/usr/bin/env bash

# First-run experience: preview and confirmation, the setup wizard and
# persona catalog, backups, the pinned yq download, and the output layer.

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
    # Friendly names from the catalog in the preview
    [[ "$out" == *"Apps       iTerm2"* && "$out" == *"Dock: auto-hide on"* ]] || fail "$out"
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
    [[ "$out" == *"[1/"*"] Command Line Tools"* ]] || fail "no step headers: $out"
    # No security section: security settings must not be touched
    [[ "$out" != *"] Security"* ]] || fail "security ran without being turned on: $out"
    [[ "$out" == *"✓ Your Mac is ready"* ]] || fail "no summary: $out"
    [[ "$out" == *"Full log:"* ]] || fail "no log path: $out"
    assert_contains "$STUB_LOG" "brew install ripgrep"
    assert_contains "$STUB_LOG" "brew install --cask iterm2"
    assert_not_contains "$STUB_LOG" "brew install jq"
    assert_eq "$(git config --global user.name)" "Ada"
    # Admin access was checked once, up front, because an app was missing
    # (without a terminal that's passwordless sudo, not a password prompt)
    assert_count "$STUB_LOG" "sudo -n true" 1
    assert_not_contains "$STUB_LOG" "sudo -v"

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

# --- wizard and catalog ---------------------------------------------------

run_wizard_with() {
    printf '%b' "$1" > "$SANDBOX/answers"
    ZAPZ_TTY="$SANDBOX/answers"
    open_prompt_input
    run_config_wizard "$SANDBOX/out.yml" > "$SANDBOX/screen.txt" 2>&1
}

# Answers, in order: name, email, personas, extras, then each pick question
# (essentials, then each persona and pack), terminal, shell, macOS, updates

test_wizard_builds_config_from_personas() {
    setup_sandbox; load_zapz
    # Software development + Video editing, the dictation pack;
    # Docker Desktop, no dev extras, Resolve + Final Cut, VoiceInk;
    # default terminal, light shell, no macOS settings, no updates
    run_wizard_with 'Grace Hopper\ngrace@example.com\n1 6\n2\n\n\n2\n0\n1 2\n\n5\n\n2\nn\nn\n'
    local f="$SANDBOX/out.yml"
    assert_eq "$(yq e '.git.user.name' "$f")" "Grace Hopper"
    assert_eq "$(yq e '.profile.chosen | join(",")' "$f")" "Software development,Video editing,Voice dictation"
    local casks
    casks=" $(yq e '.homebrew.casks | join(" ")' "$f") "
    local want
    for want in google-chrome visual-studio-code docker-desktop handbrake-app voiceink ghostty 1password; do
        [[ "$casks" == *" $want "* ]] || fail "missing cask $want in:$casks"
    done
    for want in orbstack cursor wispr-flow; do
        [[ "$casks" != *" $want "* ]] || fail "unwanted cask $want"
    done
    assert_eq "$(yq e '.apps.app_store[0].name' "$f")" "Final Cut Pro"
    assert_eq "$(yq e '.languages.tools | join(" ")' "$f")" "node@lts bun@latest pnpm@latest python@3.13"
    assert_contains "$f" "Download DaVinci Resolve"
    assert_contains "$f" "Open Docker Desktop to finish setup"
    assert_eq "$(yq e '.shell.setup' "$f")" "light"
    assert_eq "$(yq e '.homebrew.formulas | contains(["starship"])' "$f")" "true"
    assert_eq "$(yq e '.homebrew.formulas | contains(["zsh-autosuggestions"])' "$f")" "false"
    assert_eq "$(yq e '.macos' "$f")" "null" "macOS settings removed"
    assert_eq "$(yq e '.cron.update_schedule.enabled' "$f")" "false"
    assert_eq "$(yq e '.git.editor' "$f")" "code --wait"
}

test_wizard_all_defaults() {
    setup_sandbox; load_zapz
    # Enter everywhere: just the essentials and every recommendation
    run_wizard_with '\n\n\n\n\n\n\n\n\n\n'
    local f="$SANDBOX/out.yml"
    assert_eq "$(yq e '.git.user' "$f")" "null" "no identity written when left blank"
    assert_eq "$(yq e '.profile.chosen | length' "$f")" "0"
    assert_eq "$(yq e '.homebrew.casks | contains(["google-chrome", "ghostty"])' "$f")" "true"
    assert_eq "$(yq e '.languages.tools | length' "$f")" "0"
    assert_eq "$(yq e '.terminal.app' "$f")" "ghostty"
    assert_eq "$(yq e '.shell.setup' "$f")" "recommended"
    assert_eq "$(yq e '.homebrew.formulas | contains(["zsh-autosuggestions", "starship"])' "$f")" "true"
    assert_eq "$(yq e '.security.touch_id_sudo' "$f")" "true"
    assert_eq "$(yq e '.macos.dock.autohide' "$f")" "true"
    assert_eq "$(yq e '.cron.update_schedule.enabled' "$f")" "true"
}

test_wizard_re_asks_after_bad_input() {
    setup_sandbox; load_zapz
    # An out-of-range persona and a word, then a valid pick
    run_wizard_with '\n\n99\nvideo\n9\n\n\n\n\n\n\n\n\n'
    assert_eq "$(yq e '.profile.chosen | join(",")' "$SANDBOX/out.yml")" "Team collaboration"
    assert_contains "$SANDBOX/screen.txt" "Please use numbers from 1 to 9"
}

test_wizard_backs_up_existing_config() {
    setup_sandbox; load_zapz
    echo "mine: true" > "$SANDBOX/out.yml"
    ZAPZ_BACKUP_DIR="$SANDBOX/backups"
    run_wizard_with '\n\n\n\n\n\n\n\n\n\n'
    assert_contains "$SANDBOX/backups/${SANDBOX#/}/out.yml" "mine: true"
}

# Every catalog file is well formed, so the wizard can't offer a broken item
test_catalog_is_valid() {
    local file kind problems=""
    for file in "$PROJECT_ROOT"/catalog/essentials.yml "$PROJECT_ROOT"/catalog/personas/*.yml \
            "$PROJECT_ROOT"/catalog/packs/*.yml; do
        [[ "$(yq e '.id' "$file")" == "$(basename "$file" .yml)" ]] || problems+="$file: id doesn't match the file name"$'\n'
        [[ "$(yq e '.title' "$file")" != null ]] || problems+="$file: no title"$'\n'
        problems+=$(yq e '
            [.core // [], ((.picks // [])[].items), ((.core // [], ((.picks // [])[].items))[] | .with // [])]
            | flatten | .[]
            | select(
                (.kind == "formula" or .kind == "cask" or .kind == "mise") and (.name == null)
                or (.kind == "mas" and ((.id | tag) != "!!int" or .label == null))
                or (.kind == "guided" and (.url == null or .label == null))
                or (.kind == "command" and (.run == null or .label == null))
                or (.kind == "none" and .label == null)
                or ([.kind] - ["formula", "cask", "mise", "mas", "guided", "command", "none"] | length) > 0)
            | "'"$file"': bad item " + (. | tojson) + "\n"' "$file")
    done
    [[ -z "$problems" ]] || fail "$problems"
}

# The base config only uses keys zapz understands
test_base_config_uses_known_keys() {
    local example="$PROJECT_ROOT/config/default.yml.example" known used unknown
    known=$(yq e '.. | path | map(select(tag == "!!str")) | join(".")' "$example" | sort -u)
    used=$(yq e '.. | path | map(select(tag == "!!str")) | join(".")' "$PROJECT_ROOT/catalog/base.yml" | sort -u)
    unknown=$(comm -23 <(echo "$used") <(echo "$known"))
    [[ -z "$unknown" ]] || fail "catalog/base.yml uses keys missing from the example: $unknown"
}

test_installer_runs_the_wizard() {
    setup_sandbox
    stub uname 'echo Darwin'
    # name, email, AI building, no extras, defaults, don't run setup now
    printf 'Ada\nada@example.com\n2\n\n\n\n\n\n\n\n\n\nn\n' > "$SANDBOX/answers"
    local out
    out=$(ZAPZ_TTY="$SANDBOX/answers" ZAPZ_SOURCE="$PROJECT_ROOT" "$BASH" "$PROJECT_ROOT/install.sh" 2>&1)
    [[ "$out" == *"Saved your setup"* ]] || fail "$out"
    [[ "$out" == *"run zapz to preview"* ]] || fail "$out"
    local config="$HOME/.local/share/zapz/config/default.yml"
    assert_eq "$(yq e '.git.user.name' "$config")" "Ada"
    assert_contains "$config" "claude-code"
    assert_contains "$config" "conductor"
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

# --- fixes from review ----------------------------------------------------

# A copy of zapz without a config, for tests that touch config/default.yml
copy_zapz() {
    ZAPZ_COPY="$SANDBOX/zapz"
    mkdir -p "$ZAPZ_COPY"
    tar -C "$PROJECT_ROOT" --exclude=./.git --exclude=./config/default.yml -cf - . \
        | tar -C "$ZAPZ_COPY" -xf -
}

test_dry_run_doesnt_create_a_config() {
    setup_mac_sandbox
    copy_zapz
    "$BASH" "$ZAPZ_COPY/setup.sh" --dry-run > /dev/null 2>&1
    assert_no_file "$ZAPZ_COPY/config/default.yml"
}

test_configure_asks_before_replacing() {
    setup_sandbox
    copy_zapz
    echo "mine: true" > "$ZAPZ_COPY/config/default.yml"
    printf 'n\n' > "$SANDBOX/answers"
    local out
    out=$(ZAPZ_TTY="$SANDBOX/answers" "$BASH" "$ZAPZ_COPY/setup.sh" --configure 2>&1)
    [[ "$out" == *"replaces your current config"* ]] || fail "$out"
    assert_contains "$ZAPZ_COPY/config/default.yml" "mine: true"
}

test_apps_installed_outside_homebrew_are_not_failures() {
    setup_mac_sandbox
    export ZAPZ_APPLICATIONS_DIR="$SANDBOX/Applications"
    mkdir -p "$ZAPZ_APPLICATIONS_DIR/iTerm.app"
    # brew info names iTerm.app as the cask's app; installing it would fail
    cp "$STUB_BIN/brew" "$STUB_BIN/brew.base"
    stub brew '
if [[ "$1" == info ]]; then echo "{\"casks\":[{\"artifacts\":[{\"app\":[\"iTerm.app\"]}]}]}"; exit 0; fi
[[ "$1" == install && "$2" == --cask ]] && exit 1
exec "$(dirname "$0")/brew.base" "$@"'
    local out status=0
    out=$(zapz --dry-run 2>&1)
    [[ "$out" == *"all 1 already installed"* ]] || fail "preview: $out"
    out=$(ZAPZ_NONINTERACTIVE=1 zapz --yes 2>&1) || status=$?
    assert_eq "$status" 0 "exit status"
    [[ "$out" == *"installed outside Homebrew"* ]] || fail "$out"
    assert_not_contains "$STUB_LOG" "brew install --cask iterm2"
}

test_yes_without_passwordless_sudo_explains() {
    setup_mac_sandbox
    stub sudo '[[ "$1" == -n ]] && exit 1; exit 0'
    local out status=0
    out=$(ZAPZ_NONINTERACTIVE=1 zapz --yes 2>&1) || status=$?
    assert_eq "$status" 1 "exit status"
    [[ "$out" == *"no terminal to ask for a password"* ]] || fail "$out"
    assert_not_contains "$STUB_LOG" "brew install"
}

# An nvm whose install/use put a fake npm on PATH, like the real one
fake_nvm_with_npm() {
    mkdir -p "$HOME/.nvm" "$SANDBOX/node/bin"
    printf '#!/bin/sh\necho "npm $*" >> "$STUB_LOG"\n[ "$1" = list ] && exit 1\nexit 0\n' \
        > "$SANDBOX/node/bin/npm"
    chmod +x "$SANDBOX/node/bin/npm"
    {
        echo 'nvm() {'
        echo '    echo "nvm $*" >> "$STUB_LOG"'
        echo '    case "$1" in'
        echo '        version) echo N/A ;;'
        echo "        install|use) PATH=\"$SANDBOX/node/bin:\$PATH\" ;;"
        echo '    esac'
        echo '}'
    } > "$HOME/.nvm/nvm.sh"
}

test_global_packages_without_a_default_version() {
    setup_sandbox; load_zapz
    fake_nvm_with_npm
    use_config <<< 'node: { versions: ["26"], global_packages: ["pnpm"] }'
    setup_node > /dev/null
    assert_contains "$STUB_LOG" "nvm install 26"
    assert_contains "$STUB_LOG" "npm install -g pnpm"
}

test_empty_macos_step_is_skipped() {
    setup_sandbox; load_zapz
    use_config <<< 'git: {}'
    local out
    out=$(setup_macos_preferences 2>&1)
    [[ "$out" == *"none in your config"* ]] || fail "$out"
    assert_not_contains "$STUB_LOG" "osascript"
}

# --- new setup steps ------------------------------------------------------

# A fake firewall tool and FileVault: $1 = enabled|disabled, $2 = On|Off
fake_security_state() {
    printf '#!/bin/sh\necho "fw $*" >> "$STUB_LOG"\n[ "$1" = --getglobalstate ] && echo "Firewall is %s. (State = 0)"\nexit 0\n' "$1" \
        > "$SANDBOX/socketfilterfw"
    chmod +x "$SANDBOX/socketfilterfw"
    export ZAPZ_SOCKETFILTERFW="$SANDBOX/socketfilterfw"
    export ZAPZ_PAM_SUDO_LOCAL="$SANDBOX/sudo_local"
    stub fdesetup "echo 'FileVault is $2.'"
}

test_security_turns_things_on() {
    setup_sandbox; load_zapz
    fake_security_state disabled Off
    use_config <<< 'security: {touch_id_sudo: true, firewall: true, filevault_check: true}'
    setup_security > /dev/null
    assert_contains "$STUB_LOG" "sudo tee -a $SANDBOX/sudo_local"
    assert_contains "$STUB_LOG" "sudo $SANDBOX/socketfilterfw --setglobalstate on"
    [[ " ${ZAPZ_CHECKLIST[*]} " == *"Turn on FileVault"* ]] || fail "FileVault not on the checklist"
}

test_security_leaves_what_is_already_on() {
    setup_sandbox; load_zapz
    fake_security_state enabled On
    echo "auth       sufficient     pam_tid.so" > "$SANDBOX/sudo_local"
    use_config <<< 'security: {touch_id_sudo: true, firewall: true, filevault_check: true}'
    setup_security > /dev/null
    assert_not_contains "$STUB_LOG" "sudo"
    assert_eq "${#ZAPZ_CHECKLIST[@]}" 0 "checklist items"
}

test_languages_install_missing_tools_with_mise() {
    setup_sandbox; load_zapz
    echo "node@lts" > "$STUB_STATE/mise"
    stub mise '[[ "$1" == where ]] && { grep -qx "$2" "$STUB_STATE/mise"; exit $?; }; exit 0'
    use_config <<< 'languages: {tools: ["node@lts", "python@3.13"]}'
    setup_languages > /dev/null
    setup_languages > /dev/null
    assert_contains "$STUB_LOG" "mise use --global --yes python@3.13"
    assert_not_contains "$STUB_LOG" "mise use --global --yes node@lts"
    assert_count "$HOME/.zshrc" "# >>> zapz mise >>>" 1
    assert_contains "$HOME/.zshrc" 'eval "$(mise activate zsh)"'
}

# A local stand-in for the Oh My Zsh repository
fake_omz_repo() {
    local repo="$SANDBOX/omz"
    git init -q "$repo"
    touch "$repo/oh-my-zsh.sh"
    git -C "$repo" add -A
    git -C "$repo" -c user.name=t -c user.email=t@t -c commit.gpgsign=false commit -qm init
    export ZAPZ_OMZ_REPO="$repo"
}

test_ghostty_and_recommended_shell() {
    setup_sandbox; load_zapz
    fake_omz_repo
    use_config <<< 'terminal: {app: ghostty, font: "JetBrainsMono Nerd Font"}
shell: {setup: recommended}'
    setup_terminal_shell > /dev/null
    setup_terminal_shell > /dev/null
    assert_contains "$HOME/.config/ghostty/config" 'font-family = "JetBrainsMono Nerd Font"'
    assert_file "$HOME/.oh-my-zsh/oh-my-zsh.sh"
    assert_count "$HOME/.zshrc" "# >>> zapz shell >>>" 1
    assert_contains "$HOME/.zshrc" 'source "$ZSH/oh-my-zsh.sh"'
    assert_contains "$HOME/.zshrc" 'starship init zsh'
    # The shell block must parse
    zsh -n "$HOME/.zshrc" 2>/dev/null || bash -n "$HOME/.zshrc"
}

test_choosing_no_shell_setup_removes_it() {
    setup_sandbox; load_zapz
    ZAPZ_BACKUP_DIR="$SANDBOX/backups"
    use_config <<< 'shell: {setup: light}'
    setup_terminal_shell > /dev/null
    assert_contains "$HOME/.zshrc" "starship init zsh"
    use_config <<< 'shell: {setup: none}'
    setup_terminal_shell > /dev/null
    assert_not_contains "$HOME/.zshrc" "zapz shell"
    assert_contains "$SANDBOX/backups/.zshrc" "starship init zsh"
}

test_other_terminals_get_a_font_reminder() {
    setup_sandbox; load_zapz
    use_config <<< 'terminal: {app: iterm2}'
    setup_terminal_app > /dev/null
    [[ " ${ZAPZ_CHECKLIST[*]} " == *"In iTerm2, set the font"* ]] || fail "${ZAPZ_CHECKLIST[*]}"
    assert_no_file "$HOME/.config/ghostty/config"
}

test_app_store_missing_purchase_becomes_checklist() {
    setup_sandbox; load_zapz
    ZAPZ_LOG="$SANDBOX/run.log"
    stub mas '
case "$1" in
    list) echo "1289583905  Pixelmator Pro  (3.6)" ;;
    install) exit 1 ;;
esac'
    use_config <<< 'apps: {app_store: [{name: "Final Cut Pro", id: 424389933}, {name: "Pixelmator Pro", id: 1289583905}]}'
    setup_app_store > /dev/null 2>&1
    assert_contains "$STUB_LOG" "mas install 424389933"
    assert_not_contains "$STUB_LOG" "mas install 1289583905"
    assert_eq "${#ZAPZ_FAILED[@]}" 0 "an App Store sign-in isn't a failure"
    [[ " ${ZAPZ_CHECKLIST[*]} " == *"macappstore://apps.apple.com/app/id424389933"* ]] || fail "${ZAPZ_CHECKLIST[*]}"
}

test_screenshots_folder() {
    setup_sandbox; load_zapz
    use_config <<< 'macos: {screenshots: {folder: "~/Pictures/Screenshots"}}'
    setup_macos_preferences > /dev/null
    [[ -d "$HOME/Pictures/Screenshots" ]] || fail "folder not created"
    assert_contains "$STUB_LOG" "defaults write com.apple.screencapture location -string $HOME/Pictures/Screenshots"
}

test_preview_and_finish_show_new_sections() {
    setup_mac_sandbox
    fake_security_state enabled On
    echo "auth       sufficient     pam_tid.so" > "$SANDBOX/sudo_local"
    stub mise '[[ "$1" == where ]] && exit 1; exit 0'
    cat >> "$SANDBOX/config.yml" << 'YAML'
profile: {chosen: ["Video editing"]}
languages: {tools: ["node@lts"]}
terminal: {app: warp}
shell: {setup: light}
apps: {app_store: [{name: "Final Cut Pro", id: 424389933}]}
checklist:
  - {title: "Download DaVinci Resolve", url: "https://example.com/resolve"}
YAML
    local out
    out=$(zapz --dry-run 2>&1)
    local want
    for want in "For        Video editing" "Languages  node@lts" "Terminal   Warp · Starship prompt" \
            "App Store  Final Cut Pro" "You'll need to:" "Download DaVinci Resolve"; do
        [[ "$out" == *"$want"* ]] || fail "preview is missing [$want]: $out"
    done
    out=$(ZAPZ_NONINTERACTIVE=1 zapz --yes 2>&1) || true
    [[ "$out" == *"Things only you can do"*"Download DaVinci Resolve"* ]] || fail "finish: $out"
}

section "new setup steps"
run_test "security: turns on Touch ID for sudo and the firewall, flags FileVault" test_security_turns_things_on
run_test "security: leaves what's already on alone" test_security_leaves_what_is_already_on
run_test "languages: installs only missing mise tools" test_languages_install_missing_tools_with_mise
run_test "terminal: Ghostty font and the recommended shell, once" test_ghostty_and_recommended_shell
run_test "shell: choosing none removes zapz's shell block" test_choosing_no_shell_setup_removes_it
run_test "terminal: other terminals get a font reminder" test_other_terminals_get_a_font_reminder
run_test "App Store: an app you haven't bought becomes a checklist item" test_app_store_missing_purchase_becomes_checklist
run_test "macOS: screenshots go to a folder" test_screenshots_folder
run_test "the preview and finish show the new sections" test_preview_and_finish_show_new_sections

section "preview and confirmation"
run_test "--dry-run previews and changes nothing" test_dry_run_previews_without_changing_anything
run_test "--dry-run doesn't create a config" test_dry_run_doesnt_create_a_config
run_test "--configure asks before replacing a config" test_configure_asks_before_replacing
run_test "apps installed by hand aren't failures" test_apps_installed_outside_homebrew_are_not_failures
run_test "--yes without passwordless sudo explains why" test_yes_without_passwordless_sudo_explains
run_test "npm packages install without a default Node version" test_global_packages_without_a_default_version
run_test "an empty macOS step is skipped quietly" test_empty_macos_step_is_skipped
run_test "without a terminal, --yes is required" test_without_a_terminal_requires_yes
run_test "answering no changes nothing" test_declining_changes_nothing
run_test "--yes runs every step, then summarizes" test_yes_runs_everything_and_summarizes
run_test "failures are summarized and exit non-zero" test_failures_are_summarized_and_exit_nonzero
run_test "an invalid config stops before any change" test_invalid_config_stops_before_changes

section "wizard and catalog"
run_test "builds the config from personas, packs and picks" test_wizard_builds_config_from_personas
run_test "Enter everywhere gives the essentials and recommendations" test_wizard_all_defaults
run_test "re-asks after a bad answer" test_wizard_re_asks_after_bad_input
run_test "backs up the config it replaces" test_wizard_backs_up_existing_config
run_test "every catalog item is well formed" test_catalog_is_valid
run_test "the base config only uses known keys" test_base_config_uses_known_keys
run_test "the installer runs the wizard" test_installer_runs_the_wizard

section "safety"
run_test "managed blocks back up files and skip no-ops" test_managed_block_backs_up_and_skips_no_ops
run_test "a yq download with a bad checksum is rejected" test_yq_download_rejects_bad_checksum

section "output"
run_test "a failure shows only that command's output" test_failed_command_shows_only_its_own_output
run_test "housekeeping isn't counted as a change" test_housekeeping_is_not_counted_as_a_change
run_test "no color codes when output isn't a terminal" test_no_color_without_a_terminal

finish_tests
