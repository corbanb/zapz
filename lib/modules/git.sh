#!/usr/bin/env bash

# Set a global git option only if the user hasn't set it already
git_config_default() {
    if git config --global --get "$1" >/dev/null 2>&1; then
        return 1
    fi
    git config --global "$1" "$2"
}

# Ask for a git name/email that neither the config nor git has, so that
# all questions happen before the long unattended part of setup.
ask_git_identity() {
    local key label value var
    for key in user.name user.email; do
        value=$(config_get ".git.$key")
        if [[ -z "$value" ]] && ! git config --global --get "$key" >/dev/null 2>&1; then
            label="name"
            [[ "$key" == user.email ]] && label="email"
            value=$(ask "Your $label for git commits")
            var="ZAPZ_GIT_${label}"
            printf -v "$var" '%s' "$value"
        fi
    done
}

setup_git() {
    log_header "Git"

    if ! command_exists git; then
        log_error "git is missing; install the Xcode Command Line Tools first"
        exit 1
    fi

    # Only set values the config (or your answers) provide, so blank fields
    # never clobber an identity you already have
    local key value label current
    for key in user.name user.email; do
        label="name"
        [[ "$key" == user.email ]] && label="email"
        value=$(config_get ".git.$key")
        if [[ -z "$value" ]]; then
            local var="ZAPZ_GIT_${label}"
            value="${!var:-}"
        fi
        current=$(git config --global --get "$key" || true)
        if [[ -n "$value" && "$value" != "$current" ]]; then
            git config --global "$key" "$value"
            ui_item changed "$label" "$value"
        elif [[ -n "$current" ]]; then
            ui_item existing "$label" "$current"
        else
            ui_item skipped "$label" "not set"
            add_checklist "Set your git $label" "" "git config --global $key \"...\""
        fi
    done

    # Options from the config: editor, default branch and the git.config map
    local entry options=()
    value=$(config_get '.git.editor')
    [[ -z "$value" ]] || options+=("core.editor=$value")
    value=$(config_get '.git.default_branch')
    [[ -z "$value" ]] || options+=("init.defaultBranch=$value")
    while IFS= read -r entry; do
        [[ -n "$entry" ]] && options+=("$entry")
    done < <(yq e '(.git.config // {}) | to_entries | .[] | .key + "=" + (.value | tostring)' "$CONFIG_FILE")

    if ((${#options[@]} > 0)); then
        for entry in "${options[@]}"; do
            key="${entry%%=*}"
            value="${entry#*=}"
            if [[ "$(git config --global --get "$key" || true)" == "$value" ]]; then
                ui_item existing "$key" "$value"
            else
                git config --global "$key" "$value"
                ui_item changed "$key" "$value"
            fi
        done
    fi

    # Convenience aliases, without overriding the user's own
    local added=0 alias
    for alias in "co checkout" "br branch" "ci commit" "st status" \
            "unstage reset HEAD --" "last log -1 HEAD"; do
        git_config_default "alias.${alias%% *}" "${alias#* }" && added=$((added + 1))
    done
    git_config_default color.ui auto || true
    if ((added > 0)); then
        ui_item changed "aliases" "co, br, ci, st, unstage, last"
    else
        ui_item existing "aliases" "already set"
    fi
}
