#!/usr/bin/env bash

# Utility functions for the setup script

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Put Homebrew on PATH if it is installed but not yet in this shell's PATH
load_brew_shellenv() {
    local brew_bin
    for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew; do
        if [[ -x "$brew_bin" ]]; then
            eval "$("$brew_bin" shellenv)"
            return 0
        fi
    done
    return 1
}

# Check that yq is mikefarah's Go version (python-yq uses incompatible syntax)
is_compatible_yq() {
    command_exists yq && yq --version 2>&1 | grep -q "mikefarah"
}

# Ensure a compatible yq is installed (requires Homebrew)
ensure_yq() {
    if is_compatible_yq; then
        return 0
    fi

    if command_exists yq; then
        log_warning "Found incompatible yq ($(command -v yq)); zapz needs mikefarah/yq"
    fi

    log_info "Installing yq..."
    if ! brew install yq; then
        log_error "Failed to install yq"
        exit 1
    fi

    if ! is_compatible_yq; then
        log_error "An incompatible yq is still first on your PATH: $(command -v yq)"
        log_info "Remove it or put $(brew --prefix)/bin earlier in PATH, then re-run"
        exit 1
    fi
}

# Print a scalar config value, or $2 if the key is missing, null or empty.
# Usage: config_get '.git.user.name' ''
config_get() {
    local value
    # Not `// ""`: yq's alternative operator also replaces false
    value=$(yq e "$1 | select(. != null)" "$CONFIG_FILE")
    if [[ -z "$value" ]]; then
        value="${2:-}"
    fi
    printf '%s\n' "$value"
}

# Print each item of a config list, one per line (nothing if missing)
config_list() {
    yq e "($1 // [])[]" "$CONFIG_FILE"
}

# Succeeds if a boolean config value is true; $2 is the default
config_enabled() {
    [[ "$(config_get "$1" "${2:-false}")" == "true" ]]
}

# Fail if the config isn't valid YAML. Otherwise every lookup would quietly
# come back empty and setup would skip everything yet report success.
validate_configuration() {
    local errors
    if ! errors=$(yq e '.' "$CONFIG_FILE" 2>&1 >/dev/null); then
        log_error "Invalid YAML in $CONFIG_FILE:"
        printf '%s\n' "$errors" >&2
        exit 1
    fi
}

# Shell startup files for the user's shell. macOS Terminal starts login
# shells, and login bash reads only ~/.bash_profile.
shell_profile_file() {
    case "${SHELL:-}" in
        */bash) printf '%s\n' "$HOME/.bash_profile" ;;
        *) printf '%s\n' "$HOME/.zprofile" ;;
    esac
}

shell_rc_file() {
    case "${SHELL:-}" in
        */bash) printf '%s\n' "$HOME/.bash_profile" ;;
        *) printf '%s\n' "$HOME/.zshrc" ;;
    esac
}

# Write a block into a shell rc file between marker comments. An existing
# block is replaced where it is, so re-running neither duplicates it nor
# moves it past lines the user added after it.
# Usage: write_managed_block <file> <name> <content>
write_managed_block() {
    local file="$1" name="$2" content="$3"
    local begin="# >>> zapz ${name} >>>"
    local end="# <<< zapz ${name} <<<"
    local block tmp

    touch "$file"
    # Without an end marker we can't tell where the block stops
    if grep -qxF "$begin" "$file" && ! grep -qxF "$end" "$file"; then
        log_warning "$file has \"$begin\" but no \"$end\"; leaving it unchanged"
        return 0
    fi

    # Pass the content through a file: awk -v would mangle backslashes
    block=$(mktemp)
    tmp=$(mktemp)
    printf '%s\n%s\n%s\n' "$begin" "$content" "$end" > "$block"
    awk -v b="$begin" -v e="$end" -v blockfile="$block" '
        function emit(line) {
            while ((getline line < blockfile) > 0) print line
            close(blockfile)
            written = 1
        }
        $0 == b { if (!written) emit(); skipping = 1; next }
        skipping && $0 == e { skipping = 0; next }
        !skipping
        END { if (!written) emit() }
    ' "$file" > "$tmp"
    cat "$tmp" > "$file"
    rm -f "$tmp" "$block"
}

# Download file from URL
download_file() {
    local url="$1"
    local output="$2"

    if command_exists "curl"; then
        curl -fsSL "$url" -o "$output"
    elif command_exists "wget"; then
        wget -q "$url" -O "$output"
    else
        log_error "Neither curl nor wget found"
        exit 1
    fi
}

# Load configuration from file or gist
load_configuration() {
    if [[ -n "${GIST_URL:-}" ]]; then
        if [[ "$GIST_URL" != https://* ]]; then
            log_error "Gist URL must use https: $GIST_URL"
            exit 1
        fi
        log_info "Loading configuration from Gist..."
        # Private temp file: a fixed /tmp path could be pre-created or symlinked
        ZAPZ_GIST_CONFIG=$(mktemp "${TMPDIR:-/tmp}/zapz-config.XXXXXX")
        download_file "$GIST_URL" "$ZAPZ_GIST_CONFIG"
        CUSTOM_CONFIG="$ZAPZ_GIST_CONFIG"
    fi

    if [[ -n "${CUSTOM_CONFIG:-}" ]]; then
        if [[ ! -f "$CUSTOM_CONFIG" ]]; then
            log_error "Custom config file not found: $CUSTOM_CONFIG"
            exit 1
        fi
        CONFIG_FILE="$CUSTOM_CONFIG"
    else
        # Check if default config exists, if not copy from example
        if [[ ! -f "$DEFAULT_CONFIG" ]]; then
            local example_config="${DEFAULT_CONFIG}.example"
            if [[ -f "$example_config" ]]; then
                log_info "Creating default config from example..."
                cp "$example_config" "$DEFAULT_CONFIG"
            else
                log_error "Configuration file not found: $DEFAULT_CONFIG"
                log_error "Expected location: $example_config"
                exit 1
            fi
        fi
        CONFIG_FILE="$DEFAULT_CONFIG"
    fi

    # Export CONFIG_FILE so it's available to all modules
    export CONFIG_FILE

    log_debug "Using config file: $CONFIG_FILE"
}

# Check if a cask is already installed via Homebrew
is_app_installed() {
    brew list --cask "$1" >/dev/null 2>&1
}

# Check if a formula is already installed via Homebrew.
# Works with tap-qualified names like oven-sh/bun/bun.
is_formula_installed() {
    brew list --formula "$1" >/dev/null 2>&1
}
