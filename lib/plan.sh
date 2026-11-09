#!/usr/bin/env bash

# The preview shown before setup changes anything: what will be installed or
# changed, and what is already in place. It only reads.

# One row: bold label, then the text wrapped to the terminal width
_plan_row() {
    local label="$1" text="$2" width=64
    printf "  ${BOLD}%-10s${NC} " "$label"
    printf '%s\n' "$text" | fold -s -w "$width" | sed '2,$s/^/             /'
}

# Join stdin lines as "a, b, c"
_join() {
    paste -sd, - | sed 's/,/, /g'
}

# Lines of $2 (a list) that are not in $1 (a list), and the count of those that are
_partition_installed() {
    local installed="$1" wanted="$2" item missing=() present=0
    while IFS= read -r item; do
        [[ -n "$item" ]] || continue
        if grep -qxF -- "$item" <<< "$installed" || grep -qxF -- "${item##*/}" <<< "$installed"; then
            present=$((present + 1))
        else
            missing+=("$item")
        fi
    done <<< "$wanted"
    PLAN_PRESENT=$present
    PLAN_MISSING=""
    if ((${#missing[@]} > 0)); then
        PLAN_MISSING=$(printf '%s\n' "${missing[@]}" | _join)
    fi
}

# "a, b, c · 2 already installed"
_describe_packages() {
    if [[ -z "$PLAN_MISSING" && "$PLAN_PRESENT" -eq 0 ]]; then
        echo "none"
    elif [[ -z "$PLAN_MISSING" ]]; then
        echo "all $PLAN_PRESENT already installed"
    elif ((PLAN_PRESENT == 0)); then
        echo "$PLAN_MISSING"
    else
        echo "$PLAN_MISSING · $PLAN_PRESENT already installed"
    fi
}

# Set PLAN_NEEDS_ADMIN when something needs the user's password
show_plan() {
    local have_brew=false installed_formulas="" installed_casks="" text
    PLAN_NEEDS_ADMIN=false

    if command_exists brew || load_brew_shellenv; then
        have_brew=true
        installed_formulas=$(brew list --formula -1 --full-name 2>/dev/null || true)
        installed_casks=$(brew list --cask -1 2>/dev/null || true)
    fi

    printf "\n  ${BOLD}Here's what zapz will do:${NC}\n\n"

    if xcode-select -p &>/dev/null; then
        text="already installed"
    else
        text="install (Apple's installer opens)"
    fi
    _plan_row "Tools" "Command Line Tools: $text"

    if [[ "$have_brew" == true ]]; then
        text="already installed"
    else
        text="install Homebrew"
        PLAN_NEEDS_ADMIN=true
    fi
    _plan_row "Homebrew" "$text"

    _partition_installed "$installed_formulas" "$(config_list '.homebrew.formulas')"
    _plan_row "Packages" "$(_describe_packages)"

    # Apps installed by hand count as present, as they do during setup
    local casks="" cask
    while IFS= read -r cask; do
        [[ -n "$cask" ]] || continue
        if [[ "$have_brew" == true ]] && ! grep -qxF -- "$cask" <<< "$installed_casks" \
                && is_app_installed_outside_brew "$cask"; then
            installed_casks="$installed_casks"$'\n'"$cask"
        fi
        casks="$casks$cask"$'\n'
    done < <(config_list '.homebrew.casks')
    _partition_installed "$installed_casks" "$casks"
    [[ -z "$PLAN_MISSING" ]] || PLAN_NEEDS_ADMIN=true
    _plan_row "Apps" "$(_describe_packages)"

    local name email
    name=$(config_get '.git.user.name' "$(git config --global --get user.name 2>/dev/null || true)")
    email=$(config_get '.git.user.email' "$(git config --global --get user.email 2>/dev/null || true)")
    [[ -n "$name" ]] || name="name (you'll be asked)"
    [[ -n "$email" ]] || email="email (you'll be asked)"
    _plan_row "Git" "$name · $email"

    if [[ -f "$HOME/.ssh/id_ed25519" ]]; then
        text="keep your existing key"
    else
        text="new key for GitHub (you'll choose a passphrase)"
    fi
    _plan_row "SSH" "$text"

    local versions default packages
    versions=$(config_list '.node.versions' | _join)
    if [[ -z "$versions" ]]; then
        text="skipped"
    else
        default=$(config_get '.node.default')
        packages=$(config_list '.node.global_packages' | _join)
        text="$versions${default:+ (default $default)}${packages:+ · $packages}"
    fi
    _plan_row "Node.js" "$text"

    if [[ "${SKIP_MACOS:-false}" == true ]]; then
        text="skipped (--skip-macos)"
    else
        text=$(configured_macos_settings | sed 's/|/ /' | _join)
        if config_enabled '.macos.developer_mode'; then
            if DevToolsSecurity -status 2>/dev/null | grep -q enabled; then
                text="${text:+$text, }Developer Mode (already on)"
            else
                text="${text:+$text, }Developer Mode"
                PLAN_NEEDS_ADMIN=true
            fi
        fi
        text="${text:-no changes}"
    fi
    _plan_row "macOS" "$text"

    if [[ "${SKIP_SCHEDULE:-false}" == true ]]; then
        text="skipped (--skip-schedule)"
    else
        text="$(describe_schedule)"
    fi
    _plan_row "Updates" "$text"

    if command_exists gh && gh auth status >/dev/null 2>&1; then
        text="already signed in"
    elif command_exists gh || config_list '.homebrew.formulas' | grep -qx gh; then
        text="sign in with the GitHub CLI (optional, at the end)"
    else
        text="skipped (add gh to homebrew.formulas to sign in)"
    fi
    _plan_row "GitHub" "$text"

    printf "\n  ${DIM}Only missing things are installed; what you already have is left alone.${NC}\n"
    printf "  ${DIM}Shell and SSH files are backed up before they're edited.${NC}\n"
}
