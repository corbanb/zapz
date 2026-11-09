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

# Friendly names for Homebrew packages, from the catalog ("VS Code" rather
# than "visual-studio-code"). Prints "name<TAB>label" lines.
_catalog_labels() {
    local dir
    dir="$(catalog_dir 2>/dev/null)" || return 0
    [[ -d "$dir" ]] || return 0
    yq ea '[.core // [], ((.picks // [])[].items)] | flatten | .[]
        | select(.name != null and .label != null) | [.name, .label] | @tsv' \
        "$dir"/essentials.yml "$dir"/personas/*.yml "$dir"/packs/*.yml 2>/dev/null | awk -F'\t' '!seen[$1]++'
    # Terminals come from the wizard's terminal question, not the catalog
    printf 'ghostty\tGhostty\niterm2\tiTerm2\nwarp\tWarp\n'
}

# Replace names in a ", "-joined list with their friendly labels
_with_labels() {
    [[ -n "$PLAN_LABELS" ]] || { cat; return; }
    awk -F'\t' -v list="$(cat)" '
        { label[$1] = $2 }
        END {
            n = split(list, parts, ", ")
            for (i = 1; i <= n; i++) {
                out = out (i > 1 ? ", " : "") ((parts[i] in label) ? label[parts[i]] : parts[i])
            }
            print out
        }' <<< "$PLAN_LABELS"
}

# "a, b, c · 2 already installed"
_describe_packages() {
    if [[ -z "$PLAN_MISSING" && "$PLAN_PRESENT" -eq 0 ]]; then
        echo "none"
    elif [[ -z "$PLAN_MISSING" ]]; then
        echo "all $PLAN_PRESENT already installed"
    elif ((PLAN_PRESENT == 0)); then
        _with_labels <<< "$PLAN_MISSING"
    else
        echo "$(_with_labels <<< "$PLAN_MISSING") · $PLAN_PRESENT already installed"
    fi
}

# Set PLAN_NEEDS_ADMIN when something needs the user's password
show_plan() {
    local have_brew=false installed_formulas="" installed_casks="" text
    PLAN_NEEDS_ADMIN=false
    PLAN_LABELS=$(_catalog_labels)

    if command_exists brew || load_brew_shellenv; then
        have_brew=true
        installed_formulas=$(brew list --formula -1 --full-name 2>/dev/null || true)
        installed_casks=$(brew list --cask -1 2>/dev/null || true)
    fi

    printf "\n  ${BOLD}Here's what zapz will do:${NC}\n\n"

    local chosen
    chosen=$(config_list '.profile.chosen' | _join)
    [[ -z "$chosen" ]] || _plan_row "For" "$chosen"

    if xcode-select -p &>/dev/null; then
        text="already installed"
    else
        text="install (Apple's installer opens)"
    fi
    _plan_row "Tools" "Command Line Tools: $text"

    local security=()
    if config_enabled '.security.touch_id_sudo' true; then
        if touch_id_sudo_enabled; then security+=("Touch ID for sudo (on)"); else security+=("turn on Touch ID for sudo"); fi
    fi
    if config_enabled '.security.firewall' true; then
        if firewall_enabled; then security+=("firewall (on)"); else security+=("turn on the firewall"); fi
    fi
    if config_enabled '.security.filevault_check' true; then
        if filevault_on; then security+=("FileVault (on)"); else security+=("check FileVault"); fi
    fi
    if ((${#security[@]} > 0)); then
        _plan_row "Security" "$(printf '%s\n' "${security[@]}" | _join)"
    fi
    security_needs_admin && PLAN_NEEDS_ADMIN=true

    if [[ "$have_brew" == true ]]; then
        text="already installed"
    else
        text="install Homebrew"
        PLAN_NEEDS_ADMIN=true
    fi
    _plan_row "Homebrew" "$text"

    _partition_installed "$installed_formulas" "$(config_list '.homebrew.formulas')"
    _plan_row "Packages" "$(_describe_packages)"
    local new_formulas=0
    [[ -z "$PLAN_MISSING" ]] || new_formulas=$(grep -o ',' <<< "$PLAN_MISSING," | wc -l)

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
    local new_casks=0
    [[ -z "$PLAN_MISSING" ]] || new_casks=$(grep -o ',' <<< "$PLAN_MISSING," | wc -l)

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

    local tools
    tools=$(config_list '.languages.tools' | _join)
    [[ -z "$tools" ]] || _plan_row "Languages" "$tools (with mise)"

    # Older configs: Node.js with nvm
    local versions default packages
    versions=$(config_list '.node.versions' | _join)
    if [[ -n "$versions" ]]; then
        default=$(config_get '.node.default')
        packages=$(config_list '.node.global_packages' | _join)
        _plan_row "Node.js" "$versions${default:+ (default $default)}${packages:+ · $packages}"
    fi

    local terminal shell
    case "$(config_get '.terminal.app')" in
        ghostty) terminal="Ghostty" ;;
        iterm2) terminal="iTerm2" ;;
        warp) terminal="Warp" ;;
        terminal) terminal="Terminal" ;;
        *) terminal="terminal left as it is" ;;
    esac
    case "$(config_get '.shell.setup' none)" in
        recommended) shell="Oh My Zsh, suggestions, highlighting, Starship prompt" ;;
        light) shell="Starship prompt" ;;
        *) shell="shell left as it is" ;;
    esac
    _plan_row "Terminal" "$terminal · $shell"

    local app_store
    app_store=$(yq e '(.apps.app_store // [])[].name' "$CONFIG_FILE" | _join)
    [[ -z "$app_store" ]] || _plan_row "App Store" "$app_store (needs App Store sign-in)"

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

    # What will need the user, so nothing is a surprise
    local needs=()
    [[ -z "$app_store" ]] || needs+=("sign in to the App Store")
    while IFS= read -r text; do
        [[ -z "$text" ]] || needs+=("$text")
    done < <(yq e '(.checklist // [])[].title' "$CONFIG_FILE")
    if ((${#needs[@]} > 0)); then
        printf "\n  ${BOLD}You'll need to:${NC}\n"
        printf '%s\n' "${needs[@]}" | sed 's/^/    · /'
        printf "  ${DIM}These are listed again at the end, with links.${NC}\n"
    fi

    # A rough guess: a minute per app, less for command-line tools
    local minutes=$((5 + new_casks + new_formulas / 3))
    [[ -z "$tools" ]] || minutes=$((minutes + 3))
    [[ "$have_brew" == true ]] || minutes=$((minutes + 5))
    printf "\n  ${DIM}About %d minutes. Only missing things are installed; files are backed up before edits.${NC}\n" "$minutes"
}
