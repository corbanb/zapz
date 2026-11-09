#!/usr/bin/env bash

setup_homebrew() {
    log_header "Setting up Homebrew"

    # brew may be installed but not on this shell's PATH (common on Apple Silicon)
    if ! command_exists brew; then
        load_brew_shellenv || true
    fi

    if ! command_exists brew; then
        log_info "Installing Homebrew (it will ask for your password)..."
        local homebrew_installer
        homebrew_installer="$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        if [[ -t 0 ]]; then
            /bin/bash -c "$homebrew_installer"
        else
            # No one to press Return or type a password (e.g. CI)
            NONINTERACTIVE=1 /bin/bash -c "$homebrew_installer"
        fi
        if ! load_brew_shellenv; then
            log_error "Homebrew installation failed"
            exit 1
        fi
    else
        log_success "Homebrew already installed"
    fi

    # Make brew available in future login shells
    write_managed_block "$(shell_profile_file)" "homebrew" "eval \"\$($(command -v brew) shellenv)\""

    # yq is needed to read package lists from the config
    ensure_yq
    validate_configuration

    log_info "Updating Homebrew..."
    brew update

    # Keep going when a single package fails; report them all at the end
    local failed=()

    log_info "Installing Homebrew taps..."
    local tap
    while IFS= read -r tap; do
        [[ -n "$tap" ]] || continue
        if ! brew tap | grep -qx "$tap"; then
            log_debug "Adding tap: $tap"
            brew tap "$tap" || { failed+=("tap $tap"); continue; }
        fi
        # Homebrew 6+ won't load formulas from a third-party tap until it is
        # trusted. Listing a tap in your config is that decision.
        if supports_tap_trust; then
            brew trust "$tap" >/dev/null || failed+=("trust $tap")
        fi
    done < <(config_list '.homebrew.taps')

    log_info "Installing Homebrew formulas..."
    local formula
    while IFS= read -r formula; do
        [[ -n "$formula" ]] || continue
        if is_formula_installed "$formula"; then
            log_debug "Formula already installed: $formula"
        else
            log_debug "Installing formula: $formula"
            brew install "$formula" || failed+=("formula $formula")
        fi
    done < <(config_list '.homebrew.formulas')

    log_info "Installing Homebrew casks..."
    local cask
    while IFS= read -r cask; do
        [[ -n "$cask" ]] || continue
        if is_app_installed "$cask"; then
            log_debug "Cask already installed: $cask"
        else
            log_debug "Installing cask: $cask"
            # Fails if the app was installed outside Homebrew; that's fine to skip
            brew install --cask "$cask" || failed+=("cask $cask")
        fi
    done < <(config_list '.homebrew.casks')

    if ((${#failed[@]} > 0)); then
        log_warning "Some Homebrew packages could not be installed:"
        local item
        for item in "${failed[@]}"; do
            log_warning "  $item"
        done
    else
        log_success "Homebrew setup completed"
    fi
}
