#!/usr/bin/env bash

# Write a boolean `defaults` value when the config key is set.
# Usage: apply_bool_default <config path> <domain> <key>
apply_bool_default() {
    local value
    value=$(config_get "$1")
    case "$value" in
        true|false) defaults write "$2" "$3" -bool "$value" ;;
        "") ;;
        *) log_warning "Ignoring $1: expected true or false, got '$value'" ;;
    esac
}

# Write an integer `defaults` value when the config key is set
apply_int_default() {
    local value
    value=$(config_get "$1")
    if [[ "$value" =~ ^[0-9]+$ ]]; then
        defaults write "$2" "$3" -int "$value"
    elif [[ -n "$value" ]]; then
        log_warning "Ignoring $1: expected a number, got '$value'"
    fi
}

setup_macos_preferences() {
    log_header "Configuring macOS preferences"

    # Close the settings app so it doesn't overwrite our changes
    # (renamed from System Preferences in macOS 13)
    osascript -e 'tell application "System Settings" to quit' &>/dev/null || true
    osascript -e 'tell application "System Preferences" to quit' &>/dev/null || true

    log_info "Configuring Dock preferences..."
    apply_bool_default '.macos.dock.autohide' com.apple.dock autohide
    apply_bool_default '.macos.dock.magnification' com.apple.dock magnification
    apply_bool_default '.macos.dock.minimize-to-application' com.apple.dock minimize-to-application

    log_info "Configuring keyboard preferences..."
    apply_int_default '.macos.keyboard.key_repeat' NSGlobalDomain KeyRepeat
    apply_int_default '.macos.keyboard.initial_key_repeat' NSGlobalDomain InitialKeyRepeat

    log_info "Configuring Finder preferences..."
    apply_bool_default '.macos.finder.show_all_extensions' NSGlobalDomain AppleShowAllExtensions
    apply_bool_default '.macos.finder.show_hidden_files' com.apple.finder AppleShowAllFiles
    apply_bool_default '.macos.finder.show_path_bar' com.apple.finder ShowPathbar
    apply_bool_default '.macos.finder.show_status_bar' com.apple.finder ShowStatusBar

    # Lets debuggers attach without a password prompt each time; needs admin
    if config_enabled '.macos.developer_mode'; then
        log_info "Enabling Developer Mode (you may be asked for your password)..."
        sudo /usr/sbin/DevToolsSecurity -enable || log_warning "Could not enable Developer Mode"
    fi

    log_info "Restarting affected applications..."
    local app
    for app in "Dock" "Finder" "SystemUIServer"; do
        killall "$app" &>/dev/null || true
    done

    log_success "macOS preferences configured successfully"
}
