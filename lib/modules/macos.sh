#!/usr/bin/env bash

setup_macos_preferences() {
    log_header "Configuring macOS preferences"
    
    # Close System Preferences to prevent override
    osascript -e 'tell application "System Preferences" to quit'
    
    # Dock preferences
    log_info "Configuring Dock preferences..."
    
    # Auto-hide dock
    if [[ "$(yq e '.macos.dock.autohide' "$CONFIG_FILE")" == "true" ]]; then
        defaults write com.apple.dock autohide -bool true
    fi
    
    # Enable magnification
    if [[ "$(yq e '.macos.dock.magnification' "$CONFIG_FILE")" == "true" ]]; then
        defaults write com.apple.dock magnification -bool true
    fi
    
    # Keyboard preferences
    log_info "Configuring keyboard preferences..."
    
    # Set key repeat rate
    key_repeat=$(yq e '.macos.keyboard.key_repeat' "$CONFIG_FILE")
    defaults write NSGlobalDomain KeyRepeat -int "$key_repeat"
    
    # Set initial key repeat delay
    initial_repeat=$(yq e '.macos.keyboard.initial_key_repeat' "$CONFIG_FILE")
    defaults write NSGlobalDomain InitialKeyRepeat -int "$initial_repeat"
    
    # Finder preferences
    log_info "Configuring Finder preferences..."
    
    # Show all filename extensions
    defaults write NSGlobalDomain AppleShowAllExtensions -bool true
    
    # Show hidden files
    defaults write com.apple.finder AppleShowAllFiles -bool true
    
    # Show path bar
    defaults write com.apple.finder ShowPathbar -bool true
    
    # Show status bar
    defaults write com.apple.finder ShowStatusBar -bool true
    
    # Development-friendly settings
    log_info "Configuring development-friendly settings..."
    
    # Enable developer mode
    sudo /usr/sbin/DevToolsSecurity -enable &>/dev/null
    
    # Show build time in Xcode
    defaults write com.apple.dt.Xcode ShowBuildOperationDuration -bool true
    
    # Restart affected applications
    log_info "Restarting affected applications..."
    for app in "Dock" "Finder" "SystemUIServer"; do
        killall "$app" &>/dev/null || true
    done
    
    log_success "macOS preferences configured successfully"
} 