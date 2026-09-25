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
    local waited=0 timeout="${ZAPZ_XCODE_TIMEOUT:-1800}"
    until xcode-select -p &>/dev/null; do
        if ((waited >= timeout)); then
            log_error "Xcode Command Line Tools still aren't installed after $((timeout / 60)) minutes"
            log_info "Install them with 'xcode-select --install' (needs a desktop session), then run zapz again"
            exit 1
        fi
        if ((waited > 0 && waited % 60 == 0)); then
            log_info "Still waiting for the Xcode Command Line Tools installer..."
        fi
        sleep 5
        waited=$((waited + 5))
    done

    log_success "Xcode Command Line Tools installed successfully"
}
