#!/usr/bin/env bash

# Utility functions for the setup script

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Download file from URL
download_file() {
    local url="$1"
    local output="$2"
    
    if command_exists "curl"; then
        curl -fsSL "$url" -o "$output"
    elif command_exists "wget"; then
        wget -q "$url" -O "$output"
    else
        error "Neither curl nor wget found"
        exit 1
    fi
}

# Load configuration from file or gist
load_configuration() {
    if [[ -n "$GIST_URL" ]]; then
        log_info "Loading configuration from Gist..."
        download_file "$GIST_URL" "/tmp/setup_config.yml"
        CUSTOM_CONFIG="/tmp/setup_config.yml"
    fi
    
    if [[ -n "$CUSTOM_CONFIG" ]]; then
        if [[ ! -f "$CUSTOM_CONFIG" ]]; then
            error "Custom config file not found: $CUSTOM_CONFIG"
            exit 1
        fi
        CONFIG_FILE="$CUSTOM_CONFIG"
    else
        CONFIG_FILE="$DEFAULT_CONFIG"
    fi
    
    log_debug "Using config file: $CONFIG_FILE"
}

# Check if app is already installed via Homebrew
is_app_installed() {
    local app_name="$1"
    brew list --cask 2>/dev/null | grep -q "^${app_name}$"
}

# Check if formula is already installed via Homebrew
is_formula_installed() {
    local formula_name="$1"
    brew list --formula 2>/dev/null | grep -q "^${formula_name}$"
} 