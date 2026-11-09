#!/usr/bin/env bash

ZAPZ_SSH_KEY_CREATED=false

setup_ssh() {
    log_header "SSH key"

    local ssh_dir="$HOME/.ssh"
    local ssh_key="$ssh_dir/id_ed25519"
    local ssh_config="$ssh_dir/config"

    mkdir -p "$ssh_dir"
    chmod 700 "$ssh_dir"

    if [[ -f "$ssh_key" ]]; then
        ui_item existing "id_ed25519" "keeping your existing key"
    else
        local key_comment
        key_comment=$(config_get '.git.user.email' "${ZAPZ_GIT_email:-$(git config --global --get user.email 2>/dev/null || true)}")

        printf "  Creating an SSH key for GitHub. Choose a passphrase;\n"
        printf "  macOS remembers it in your Keychain, so you won't type it again.\n"
        # No -N: prompt for a passphrase rather than creating an unprotected key
        ssh-keygen -q -t ed25519 -C "$key_comment" -f "$ssh_key" <&"${ZAPZ_PROMPT_FD:-0}"
        ZAPZ_SSH_KEY_CREATED=true
        ui_item changed "id_ed25519" "new key"

        # macOS already runs an ssh-agent; store the passphrase in the
        # Keychain. Only Apple's ssh-add has --apple-use-keychain, so don't
        # pick up Homebrew's openssh from PATH.
        local ssh_add="${ZAPZ_SSH_ADD:-/usr/bin/ssh-add}"
        [[ -x "$ssh_add" ]] || ssh_add=ssh-add
        if "$ssh_add" --apple-use-keychain "$ssh_key" <&"${ZAPZ_PROMPT_FD:-0}" >/dev/null 2>&1; then
            ui_item changed "Keychain" "passphrase saved"
        else
            ui_item skipped "Keychain" "couldn't save passphrase"
        fi
    fi

    if [[ ! -f "$ssh_config" ]]; then
        cat > "$ssh_config" << EOF
# UseKeychain is Apple-only; let other ssh builds (e.g. Homebrew's) skip it
IgnoreUnknown UseKeychain

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
        ui_item changed "SSH config" "created"
    elif ! grep -qE '^[[:space:]]*Host[[:space:]]+github\.com([[:space:]]|$)' "$ssh_config"; then
        # Prepend so it takes precedence over any existing `Host *` block.
        # The trailing `Host *` keeps options at the top of the user's file
        # (Include, IdentityAgent, ...) applying to every host.
        local tmp
        tmp=$(mktemp)
        cat > "$tmp" << EOF
# UseKeychain is Apple-only; let other ssh builds (e.g. Homebrew's) skip it
IgnoreUnknown UseKeychain

# GitHub (added by zapz)
Host github.com
    AddKeysToAgent yes
    UseKeychain yes
    IdentityFile $ssh_key

Host *
EOF
        cat "$ssh_config" >> "$tmp"
        backup_file "$ssh_config"
        cat "$tmp" > "$ssh_config"
        rm -f "$tmp"
        ui_item changed "SSH config" "added github.com"
    else
        ui_item existing "SSH config" "github.com already set up"
    fi
}

# Sign in to the GitHub CLI, which also offers to upload the SSH key, so
# there's nothing to copy and paste. Runs last because it opens a browser.
setup_github() {
    log_header "GitHub"

    if ! command_exists gh; then
        ui_item skipped "GitHub CLI" "not installed (add \"gh\" to homebrew.formulas)"
        github_key_next_step
        return 0
    fi

    gh config set git_protocol ssh >/dev/null 2>&1 || true
    local editor
    editor=$(git config --global --get core.editor || true)
    [[ -z "$editor" ]] || gh config set editor "$editor" >/dev/null 2>&1 || true

    if gh auth status >/dev/null 2>&1; then
        ui_item existing "GitHub CLI" "already signed in"
        return 0
    fi

    if [[ -n "${ZAPZ_PROMPT_FD:-}" ]] \
            && confirm "  Sign in to GitHub now? It opens your browser and can upload your SSH key." Y; then
        notify "Sign in to GitHub in your browser to finish setup"
        if gh auth login --hostname github.com --git-protocol ssh --web <&"$ZAPZ_PROMPT_FD"; then
            ui_item changed "GitHub CLI" "signed in"
            return 0
        fi
        ui_item skipped "GitHub CLI" "sign-in didn't finish"
    else
        ui_item skipped "GitHub CLI" "not signed in"
    fi
    add_checklist "Sign in to GitHub" "" "gh auth login --git-protocol ssh --web"
    github_key_next_step
}

# If the key was just created and not uploaded, say how to add it
github_key_next_step() {
    [[ "$ZAPZ_SSH_KEY_CREATED" == true && -f "$HOME/.ssh/id_ed25519.pub" ]] || return 0
    if command_exists pbcopy; then
        pbcopy < "$HOME/.ssh/id_ed25519.pub"
        add_checklist "Add your SSH key to GitHub (it's on your clipboard)" "https://github.com/settings/ssh/new"
    else
        add_checklist "Add ~/.ssh/id_ed25519.pub to GitHub" "https://github.com/settings/ssh/new"
    fi
}
