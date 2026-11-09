#!/usr/bin/env bash

setup_homebrew() {
    log_header "Homebrew"

    # brew may be installed but not on this shell's PATH (common on Apple Silicon)
    if ! command_exists brew; then
        load_brew_shellenv || true
    fi

    if command_exists brew; then
        ui_item existing "Homebrew" "already installed"
    else
        local homebrew_installer
        homebrew_installer=$(mktemp)
        if ! curl -fsSL -o "$homebrew_installer" https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh; then
            rm -f "$homebrew_installer"
            log_error "Couldn't download the Homebrew installer. Check your internet connection."
            exit 1
        fi
        # Non-interactive: setup already asked for your password once (sudo -v)
        local installed=true
        run_quiet "Homebrew" env NONINTERACTIVE=1 /bin/bash "$homebrew_installer" || installed=false
        rm -f "$homebrew_installer"
        if [[ "$installed" != true ]] || ! load_brew_shellenv; then
            log_error "Homebrew installation failed; see the log above"
            exit 1
        fi
    fi

    # Make brew available in future login shells
    write_managed_block "$(shell_profile_file)" "homebrew" "eval \"\$($(command -v brew) shellenv)\""

    run_quiet --housekeeping "Update package lists" brew update || true

    local tap
    while IFS= read -r tap; do
        [[ -n "$tap" ]] || continue
        if brew tap | grep -qx "$tap"; then
            ui_item existing "$tap" "tap already added"
        else
            run_quiet --watch "$tap" brew tap "$tap" || continue
        fi
        # Homebrew 6+ won't load formulas from a third-party tap until it is
        # trusted. Listing a tap in your config is that decision.
        if supports_tap_trust; then
            brew trust "$tap" >/dev/null 2>&1 || ui_item failed "$tap" "couldn't trust tap"
        fi
    done < <(config_list '.homebrew.taps')

    local formula
    while IFS= read -r formula; do
        [[ -n "$formula" ]] || continue
        if is_formula_installed "$formula"; then
            ui_item existing "$formula" "already installed"
        else
            run_quiet --watch "$formula" brew install "$formula" || true
        fi
    done < <(config_list '.homebrew.formulas')

    local cask
    while IFS= read -r cask; do
        [[ -n "$cask" ]] || continue
        if is_app_installed "$cask"; then
            ui_item existing "$cask" "already installed"
        elif is_app_installed_outside_brew "$cask"; then
            ui_item existing "$cask" "installed outside Homebrew"
        else
            # A failure is reported in the summary and setup carries on
            run_quiet --watch "$cask" brew install --cask "$cask" || true
        fi
    done < <(config_list '.homebrew.casks')
}
