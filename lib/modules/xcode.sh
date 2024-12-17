#!/usr/bin/env bash

install_xcode_tools() {
    log_header "Checking Xcode Command Line Tools"
    
    # Check if xcode-select is already installed
    if xcode-select -p &>/dev/null; then
        log_success "Xcode Command Line Tools already installed"
        return 0
    fi
    
    log_info "Installing Xcode Command Line Tools..."
    
    # Trigger installation prompt
    xcode-select --install &>/dev/null
    
    # Wait for installation to complete
    until xcode-select -p &>/dev/null; do
        log_info "Waiting for Xcode Command Line Tools installation to complete..."
        sleep 5
    done
    
    log_success "Xcode Command Line Tools installed successfully"
} 