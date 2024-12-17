#!/usr/bin/env bash

setup_ssh() {
    log_header "Setting up SSH and GitHub configuration"
    
    local ssh_dir="$HOME/.ssh"
    local ssh_key="$ssh_dir/id_ed25519"
    local ssh_config="$ssh_dir/config"
    
    # Create SSH directory if it doesn't exist
    mkdir -p "$ssh_dir"
    chmod 700 "$ssh_dir"
    
    # Generate SSH key if it doesn't exist
    if [[ ! -f "$ssh_key" ]]; then
        log_info "Generating SSH key..."
        
        # Get email from git config for SSH key
        local git_email
        git_email=$(yq e '.git.user.email' "$CONFIG_FILE")
        
        # Generate Ed25519 key
        ssh-keygen -t ed25519 -C "$git_email" -f "$ssh_key" -N ""
        
        # Start ssh-agent and add key
        eval "$(ssh-agent -s)"
        ssh-add "$ssh_key"
        
        # Add to keychain on macOS
        ssh-add --apple-use-keychain "$ssh_key"
    else
        log_success "SSH key already exists"
    fi
    
    # Create/update SSH config
    if [[ ! -f "$ssh_config" ]]; then
        log_info "Creating SSH config..."
        cat > "$ssh_config" << EOF
# GitHub
Host github.com
    AddKeysToAgent yes
    UseKeychain yes
    IdentityFile $ssh_key

# Default settings
Host *
    AddKeysToAgent yes
    UseKeychain yes
    IdentitiesOnly yes
    ServerAliveInterval 60
EOF
        chmod 600 "$ssh_config"
    fi
    
    # Configure GitHub CLI if installed
    if command_exists gh; then
        log_info "Configuring GitHub CLI..."
        
        # Check if already authenticated
        if ! gh auth status &>/dev/null; then
            log_info "Please authenticate with GitHub..."
            gh auth login --git-protocol ssh --web
        else
            log_success "GitHub CLI already authenticated"
        fi
        
        # Configure GitHub CLI preferences
        gh config set git_protocol ssh
        gh config set editor "$(git config --get core.editor)"
    fi
    
    # Copy SSH public key to clipboard
    if [[ -f "${ssh_key}.pub" ]]; then
        pbcopy < "${ssh_key}.pub"
        log_info "SSH public key has been copied to clipboard"
        log_info "Please add it to your GitHub account: https://github.com/settings/keys"
    fi
    
    log_success "SSH and GitHub configuration completed"
} 