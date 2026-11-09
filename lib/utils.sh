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

# zapz reads its config with yq. A pinned, checksum-verified copy is
# downloaded into $ZAPZ_ROOT/bin, so the config can be read (and previewed)
# before anything else is installed. A compatible yq already on PATH is used
# as is.
ZAPZ_YQ_VERSION="v4.54.2"

_yq_sha256() {
    case "$1" in
        arm64) echo "34923a7ca09a32a4257702ced5f7f2e5e83b16968cce3866f5ff830e4ce1cdd4" ;;
        amd64) echo "651e61c6a13085d6a88d30c54fa74e894d4bb18461b5e8522d3dd00a327fb3bd" ;;
        *) return 1 ;;
    esac
}

ensure_yq() {
    is_compatible_yq && return 0

    local bin_dir="${ZAPZ_ROOT}/bin"
    if [[ ! -x "$bin_dir/yq" ]] || ! "$bin_dir/yq" --version 2>&1 | grep -q mikefarah; then
        local arch expected actual tmp
        case "$(uname -m)" in
            arm64|aarch64) arch=arm64 ;;
            x86_64) arch=amd64 ;;
            *) log_error "Unsupported CPU: $(uname -m)"; exit 1 ;;
        esac
        expected=$(_yq_sha256 "$arch")
        tmp=$(mktemp)
        if ! curl -fsSL --retry 2 -o "$tmp" \
                "https://github.com/mikefarah/yq/releases/download/${ZAPZ_YQ_VERSION}/yq_darwin_${arch}"; then
            rm -f "$tmp"
            log_error "Couldn't download yq (needed to read your config). Check your internet connection."
            exit 1
        fi
        actual=$(shasum -a 256 "$tmp" 2>/dev/null || sha256sum "$tmp")
        if [[ "${actual%% *}" != "$expected" ]]; then
            rm -f "$tmp"
            log_error "The downloaded yq didn't match its expected checksum; not using it"
            exit 1
        fi
        mkdir -p "$bin_dir"
        chmod 755 "$tmp"
        mv "$tmp" "$bin_dir/yq"
    fi
    export PATH="$bin_dir:$PATH"
}

# Where this run's backups go; files are copied there before zapz edits them
ZAPZ_RUN_ID="${ZAPZ_RUN_ID:-$(date +%Y%m%d-%H%M%S)}"
ZAPZ_BACKUP_DIR="${ZAPZ_BACKUP_DIR:-$HOME/.local/state/zapz/backups/$ZAPZ_RUN_ID}"

# Copy a file into this run's backup directory (once per run)
backup_file() {
    local file="$1" dest
    [[ -f "$file" ]] || return 0
    case "$file" in
        "$HOME"/*) dest="$ZAPZ_BACKUP_DIR/${file#"$HOME"/}" ;;
        *) dest="$ZAPZ_BACKUP_DIR/${file#/}" ;;
    esac
    [[ -e "$dest" ]] && return 0
    mkdir -p "$(dirname "$dest")"
    cp -p "$file" "$dest"
}

# Questions for the user. They read from $ZAPZ_TTY (default /dev/tty) so they
# work under `curl | bash`, where stdin is the script itself.
can_prompt() {
    [[ -z "${ZAPZ_NONINTERACTIVE:-}" ]] || return 1
    # Already open, e.g. handed over by install.sh when it starts setup
    if [[ -n "${ZAPZ_PROMPT_FD:-}" ]] && { true <&"$ZAPZ_PROMPT_FD"; } 2>/dev/null; then
        return 0
    fi
    if [[ -n "${ZAPZ_TTY:-}" ]]; then
        [[ -r "$ZAPZ_TTY" ]]
    else
        { : < /dev/tty; } 2>/dev/null
    fi
}

# Usage: ask <prompt> [default]  (prints the answer)
ask() {
    local prompt="$1" default="${2:-}" reply=""
    if [[ -n "$default" ]]; then
        printf '%s [%s]: ' "$prompt" "$default" >&2
    else
        printf '%s: ' "$prompt" >&2
    fi
    IFS= read -r reply <&"${ZAPZ_PROMPT_FD:-0}" || true
    # Echo answers that came from a file so transcripts read naturally
    [[ -t "${ZAPZ_PROMPT_FD:-0}" ]] || printf '%s\n' "$reply" >&2
    printf '%s\n' "${reply:-$default}"
}

# Usage: confirm <prompt> [Y|N]  (succeeds on yes)
confirm() {
    local answer default="${2:-Y}" hint="[Y/n]"
    [[ "$default" == Y ]] || hint="[y/N]"
    printf '%s %s ' "$1" "$hint" >&2
    IFS= read -r answer <&"${ZAPZ_PROMPT_FD:-0}" || answer=""
    [[ -t "${ZAPZ_PROMPT_FD:-0}" ]] || printf '%s\n' "$answer" >&2
    answer="${answer:-$default}"
    [[ "$answer" == [Yy]* ]]
}

# Open the prompt input on fd 9 (call once, before ask/confirm)
open_prompt_input() {
    if [[ -n "${ZAPZ_PROMPT_FD:-}" ]] && { true <&"$ZAPZ_PROMPT_FD"; } 2>/dev/null; then
        return 0
    fi
    exec 9< "${ZAPZ_TTY:-/dev/tty}"
    ZAPZ_PROMPT_FD=9
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

    # Create it if missing, but don't touch an existing file's timestamp
    [[ -e "$file" ]] || : > "$file"
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
    rm -f "$block"

    # Leave the file alone (no backup, no new timestamp) when nothing changes
    if cmp -s "$tmp" "$file"; then
        rm -f "$tmp"
        return 0
    fi
    [[ ! -s "$file" ]] || backup_file "$file"
    cat "$tmp" > "$file"
    rm -f "$tmp"
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

# Homebrew 6 added `brew trust` (tap trust); older versions don't have it
supports_tap_trust() {
    brew trust --help >/dev/null 2>&1
}

# Check if a formula is already installed via Homebrew.
# Works with tap-qualified names like oven-sh/bun/bun.
is_formula_installed() {
    brew list --formula "$1" >/dev/null 2>&1
}
