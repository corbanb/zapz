#!/usr/bin/env bash

ZAPZ_NVM_VERSION="v0.41.0"

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
    log_header "Node.js"

    if [[ -z "$(config_list '.node.versions')" ]]; then
        ui_item skipped "Node.js" "no versions in node.versions"
        return 0
    fi

    if load_nvm; then
        ui_item existing "nvm" "already installed"
    else
        # PROFILE=/dev/null: the installer shouldn't edit rc files; zapz manages that
        run_quiet "nvm ${ZAPZ_NVM_VERSION}" /bin/bash -c \
            "curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/${ZAPZ_NVM_VERSION}/install.sh | PROFILE=/dev/null bash" \
            || true
        if ! load_nvm; then
            log_error "nvm couldn't be installed; see the log above"
            exit 1
        fi
    fi

    # Load nvm in new shells
    write_managed_block "$(shell_rc_file)" "nvm" 'export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"'

    local version installed
    while IFS= read -r version; do
        [[ -n "$version" ]] || continue
        # `nvm version` prints N/A for versions that aren't installed
        installed=$(nvm_run version "$version" 2>/dev/null || true)
        if [[ -n "$installed" && "$installed" != "N/A" ]]; then
            ui_item existing "Node.js $version" "$installed"
        else
            run_quiet "Node.js $version" nvm_run install "$version" || true
        fi
    done < <(config_list '.node.versions')

    local default_version current_default
    default_version=$(config_get '.node.default')
    if [[ -n "$default_version" ]]; then
        current_default=$(nvm_run alias default 2>/dev/null | head -n1 || true)
        nvm_run alias default "$default_version" >/dev/null 2>&1 || true
        nvm_run use default >/dev/null 2>&1 || true
        if [[ "$current_default" == *"$default_version"* ]]; then
            ui_item existing "default version" "$default_version"
        else
            ui_item changed "default version" "$default_version"
        fi
    fi

    if command_exists npm; then
        local package
        while IFS= read -r package; do
            [[ -n "$package" ]] || continue
            if npm list -g --depth=0 "$package" &>/dev/null; then
                ui_item existing "$package" "already installed"
            else
                run_quiet "$package" npm install -g "$package" || true
            fi
        done < <(config_list '.node.global_packages')
    fi
}
