#!/usr/bin/env bash

ZAPZ_NVM_VERSION="v0.40.8"

# nvm isn't safe under `set -eu`, so relax strict mode around nvm calls
# and restore whatever the caller had afterwards.
_nvm_strict_off() { _ZAPZ_SHELL_OPTS=$-; set +eu; }
_nvm_strict_restore() {
    [[ "$_ZAPZ_SHELL_OPTS" != *e* ]] || set -e
    [[ "$_ZAPZ_SHELL_OPTS" != *u* ]] || set -u
}

nvm_run() {
    local status=0
    _nvm_strict_off
    nvm "$@" || status=$?
    _nvm_strict_restore
    return "$status"
}

load_nvm() {
    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
    [[ -s "$NVM_DIR/nvm.sh" ]] || return 1
    _nvm_strict_off
    # shellcheck disable=SC1091
    . "$NVM_DIR/nvm.sh"
    _nvm_strict_restore
    command -v nvm >/dev/null 2>&1
}

setup_node() {
    log_header "Setting up Node.js environment"

    # Install NVM if not already installed
    if ! load_nvm; then
        log_info "Installing NVM ${ZAPZ_NVM_VERSION}..."
        # PROFILE=/dev/null: the installer shouldn't edit rc files; zapz manages that
        curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${ZAPZ_NVM_VERSION}/install.sh" | PROFILE=/dev/null bash
        if ! load_nvm; then
            log_error "NVM installation failed or not loaded"
            exit 1
        fi
    else
        log_success "NVM already installed"
    fi

    # Load nvm in new shells
    local rc_file
    for rc_file in "$HOME/.zshrc" "$HOME/.bashrc"; do
        write_managed_block "$rc_file" "nvm" 'export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"'
    done

    # Install Node versions from config
    log_info "Installing Node.js versions..."
    local version installed
    while IFS= read -r version; do
        [[ -n "$version" ]] || continue
        # `nvm version` prints N/A for versions that aren't installed
        installed=$(nvm_run version "$version" 2>/dev/null || true)
        if [[ -n "$installed" && "$installed" != "N/A" ]]; then
            log_debug "Node.js $version already installed"
        else
            log_debug "Installing Node.js $version"
            nvm_run install "$version"
        fi
    done < <(config_list '.node.versions')

    # Set default Node version
    local default_version
    default_version=$(config_get '.node.default')
    if [[ -n "$default_version" ]]; then
        log_info "Setting default Node.js version to $default_version"
        nvm_run alias default "$default_version"
        nvm_run use default >/dev/null
    fi

    # Install global npm packages
    if command_exists npm; then
        log_info "Installing global npm packages..."
        local package
        while IFS= read -r package; do
            [[ -n "$package" ]] || continue
            if npm list -g --depth=0 "$package" &>/dev/null; then
                log_debug "Global package already installed: $package"
            else
                log_debug "Installing global package: $package"
                npm install -g "$package" || log_warning "Failed to install npm package: $package"
            fi
        done < <(config_list '.node.global_packages')
    fi

    log_success "Node.js environment setup completed"
}
