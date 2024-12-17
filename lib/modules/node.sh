#!/usr/bin/env bash

setup_node() {
    log_header "Setting up Node.js environment"
    
    # Install NVM if not already installed
    if [[ ! -d "$HOME/.nvm" ]]; then
        log_info "Installing NVM..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
        
        # Add NVM to current shell session
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    else
        log_success "NVM already installed"
    fi
    
    # Ensure NVM is loaded
    if ! command_exists nvm; then
        log_error "NVM installation failed or not loaded"
        exit 1
    fi
    
    # Install Node versions from config
    log_info "Installing Node.js versions..."
    while IFS= read -r version; do
        if [[ -n "$version" ]]; then
            if ! nvm ls "$version" &>/dev/null; then
                log_debug "Installing Node.js $version"
                nvm install "$version"
            else
                log_debug "Node.js $version already installed"
            fi
        fi
    done < <(yq e '.node.versions[]' "$CONFIG_FILE")
    
    # Set default Node version
    default_version=$(yq e '.node.default' "$CONFIG_FILE")
    log_info "Setting default Node.js version to $default_version"
    nvm alias default "$default_version"
    nvm use default
    
    # Install global npm packages
    log_info "Installing global npm packages..."
    while IFS= read -r package; do
        if [[ -n "$package" ]]; then
            if ! npm list -g "$package" &>/dev/null; then
                log_debug "Installing global package: $package"
                npm install -g "$package"
            else
                log_debug "Global package already installed: $package"
            fi
        fi
    done < <(yq e '.node.global_packages[]' "$CONFIG_FILE")
    
    # Install Bun
    if ! command_exists bun; then
        log_info "Installing Bun..."
        curl -fsSL https://bun.sh/install | bash
    else
        log_success "Bun already installed"
    fi
    
    # Install Deno
    if ! command_exists deno; then
        log_info "Installing Deno..."
        curl -fsSL https://deno.land/x/install/install.sh | sh
    else
        log_success "Deno already installed"
    fi
    
    log_success "Node.js environment setup completed"
} 