#!/usr/bin/env bash

# Set a global git option only if the user hasn't set it already
git_config_default() {
    if ! git config --global --get "$1" >/dev/null 2>&1; then
        git config --global "$1" "$2"
    fi
}

setup_git() {
    log_header "Setting up Git configuration"

    # Ensure git is installed
    if ! command_exists git; then
        log_error "Git is not installed. Please run setup_homebrew first."
        exit 1
    fi

    # Only set values the config provides, so blank fields never
    # clobber an identity the user already has
    log_info "Configuring Git user settings..."
    local key value
    for key in user.name user.email; do
        value=$(config_get ".git.$key")
        if [[ -n "$value" ]]; then
            git config --global "$key" "$value"
        elif ! git config --global --get "$key" >/dev/null 2>&1; then
            log_warning "git $key is not set; add git.$key to your config or run: git config --global $key \"...\""
        fi
    done

    value=$(config_get '.git.editor')
    [[ -z "$value" ]] || git config --global core.editor "$value"

    value=$(config_get '.git.default_branch')
    [[ -z "$value" ]] || git config --global init.defaultBranch "$value"

    # Arbitrary options from the git.config map, e.g. pull.rebase: "true"
    local entry
    while IFS= read -r entry; do
        [[ -n "$entry" ]] || continue
        git config --global "${entry%%=*}" "${entry#*=}"
    done < <(yq e '(.git.config // {}) | to_entries | .[] | .key + "=" + (.value | tostring)' "$CONFIG_FILE")

    # Convenience aliases, without overriding the user's own
    log_info "Setting up Git aliases..."
    git_config_default alias.co checkout
    git_config_default alias.br branch
    git_config_default alias.ci commit
    git_config_default alias.st status
    git_config_default alias.unstage 'reset HEAD --'
    git_config_default alias.last 'log -1 HEAD'
    git_config_default color.ui auto

    log_success "Git configuration completed"
}
