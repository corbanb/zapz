#!/usr/bin/env bash

install_xcode_tools() {
    log_header "Checking Xcode Command Line Tools"

    # Check if xcode-select is already installed
    if xcode-select -p &>/dev/null; then
        log_success "Xcode Command Line Tools already installed"
        return 0
    fi

    log_info "Installing Xcode Command Line Tools..."

    # Opens the installer dialog; exits non-zero if an install is already pending
    xcode-select --install &>/dev/null || true

    log_info "Finish the installer dialog to continue (this can take several minutes)"
    until xcode-select -p &>/dev/null; do
        sleep 5
    done

    log_success "Xcode Command Line Tools installed successfully"
}
