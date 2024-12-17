#!/usr/bin/env bash

setup_homebrew() {
    log_header "Setting up Homebrew"
    
    # Install Homebrew if not already installed
    if ! command_exists brew; then
        log_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH for Apple Silicon Macs
        if [[ "$(uname -m)" == "arm64" ]]; then
            echo "eval \"\$(/opt/homebrew/bin/brew shellenv)\"" >> "$HOME/.zprofile"
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    else
        log_success "Homebrew already installed"
    fi
    
    # Update Homebrew
    log_info "Updating Homebrew..."
    brew update
    
    # Install taps
    log_info "Installing Homebrew taps..."
    while IFS= read -r tap; do
        if [[ -n "$tap" ]]; then
            if ! brew tap | grep -q "^${tap}$"; then
                log_debug "Adding tap: $tap"
                brew tap "$tap"
            fi
        fi
    done < <(yq e '.homebrew.taps[]' "$CONFIG_FILE")
    
    # Install formulas
    log_info "Installing Homebrew formulas..."
    while IFS= read -r formula; do
        if [[ -n "$formula" ]]; then
            if ! is_formula_installed "$formula"; then
                log_debug "Installing formula: $formula"
                brew install "$formula"
            else
                log_debug "Formula already installed: $formula"
            fi
        fi
    done < <(yq e '.homebrew.formulas[]' "$CONFIG_FILE")
    
    # Install casks
    log_info "Installing Homebrew casks..."
    while IFS= read -r cask; do
        if [[ -n "$cask" ]]; then
            if ! is_app_installed "$cask"; then
                log_debug "Installing cask: $cask"
                brew install --cask "$cask"
            else
                log_debug "Cask already installed: $cask"
            fi
        fi
    done < <(yq e '.homebrew.casks[]' "$CONFIG_FILE")
    
    log_success "Homebrew setup completed"
} 