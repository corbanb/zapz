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
        log_info "Choose a passphrase; macOS will remember it in your Keychain"

        local key_comment
        key_comment=$(config_get '.git.user.email' "$(git config --global --get user.email 2>/dev/null || true)")

        # No -N: prompt for a passphrase rather than creating an unprotected key
        ssh-keygen -t ed25519 -C "$key_comment" -f "$ssh_key"

        # macOS already runs an ssh-agent; store the passphrase in the Keychain
        ssh-add --apple-use-keychain "$ssh_key" || log_warning "Could not add key to the ssh-agent"
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
    ServerAliveInterval 60
EOF
        chmod 600 "$ssh_config"
    elif ! grep -qE '^[[:space:]]*Host[[:space:]]+github\.com([[:space:]]|$)' "$ssh_config"; then
        log_info "Adding GitHub entry to existing SSH config..."
        # Prepend so it takes precedence over any existing `Host *` block.
        # The trailing `Host *` keeps options at the top of the user's file
        # (Include, IdentityAgent, ...) applying to every host.
        local tmp
        tmp=$(mktemp)
        cat > "$tmp" << EOF
# GitHub (added by zapz)
Host github.com
    AddKeysToAgent yes
    UseKeychain yes
    IdentityFile $ssh_key

Host *
EOF
        cat "$ssh_config" >> "$tmp"
        cat "$tmp" > "$ssh_config"
        rm -f "$tmp"
    fi

    # Configure GitHub CLI if installed
    if command_exists gh; then
        log_info "Configuring GitHub CLI..."

        # Check if already authenticated
        if ! gh auth status &>/dev/null; then
            log_info "Please authenticate with GitHub..."
            gh auth login --git-protocol ssh --web || log_warning "GitHub CLI login skipped"
        else
            log_success "GitHub CLI already authenticated"
        fi

        gh config set git_protocol ssh

        local editor
        editor=$(git config --global --get core.editor || true)
        [[ -z "$editor" ]] || gh config set editor "$editor"
    fi

    # Copy SSH public key to clipboard
    if [[ -f "${ssh_key}.pub" ]] && command_exists pbcopy; then
        pbcopy < "${ssh_key}.pub"
        log_info "SSH public key has been copied to clipboard"
        log_info "Please add it to your GitHub account: https://github.com/settings/keys"
    fi

    log_success "SSH and GitHub configuration completed"
}
