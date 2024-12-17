#!/usr/bin/env bash

setup_git() {
    log_header "Setting up Git configuration"
    
    # Ensure git is installed
    if ! command_exists git; then
        log_error "Git is not installed. Please run setup_homebrew first."
        exit 1
    fi
    
    # Configure git user
    local git_name
    local git_email
    
    git_name=$(yq e '.git.user.name' "$CONFIG_FILE")
    git_email=$(yq e '.git.user.email' "$CONFIG_FILE")
    
    log_info "Configuring Git user settings..."
    git config --global user.name "$git_name"
    git config --global user.email "$git_email"
    
    # Configure default editor
    local git_editor
    git_editor=$(yq e '.git.editor' "$CONFIG_FILE")
    git config --global core.editor "$git_editor"
    
    # Configure default branch name
    local default_branch
    default_branch=$(yq e '.git.default_branch' "$CONFIG_FILE")
    git config --global init.defaultBranch "$default_branch"
    
    # Configure useful aliases
    log_info "Setting up Git aliases..."
    git config --global alias.co checkout
    git config --global alias.br branch
    git config --global alias.ci commit
    git config --global alias.st status
    git config --global alias.unstage 'reset HEAD --'
    git config --global alias.last 'log -1 HEAD'
    
    # Configure pull strategy
    git config --global pull.rebase false
    
    # Enable helpful git colors
    git config --global color.ui true
    
    log_success "Git configuration completed"
} 