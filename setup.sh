#!/usr/bin/env bash

# zapz: set up a macOS development environment
# https://github.com/corbanb/zapz
# License: MIT

# Strict mode
set -euo pipefail

# Directory containing this script, following symlinks so the `zapz`
# symlink in ~/.local/bin still finds lib/ next to the real script
resolve_script_dir() {
    local path="$1" dir
    while [[ -L "$path" ]]; do
        dir="$(cd -P "$(dirname "$path")" && pwd)"
        path="$(readlink "$path")"
        [[ "$path" == /* ]] || path="$dir/$path"
    done
    cd -P "$(dirname "$path")" && pwd
}

ZAPZ_ROOT="$(resolve_script_dir "${BASH_SOURCE[0]}")"

# shellcheck source=lib/version.sh
source "${ZAPZ_ROOT}/lib/version.sh"
# shellcheck source=lib/logging.sh
source "${ZAPZ_ROOT}/lib/logging.sh"
# shellcheck source=lib/utils.sh
source "${ZAPZ_ROOT}/lib/utils.sh"
# shellcheck source=lib/plan.sh
source "${ZAPZ_ROOT}/lib/plan.sh"
# shellcheck source=lib/configure.sh
source "${ZAPZ_ROOT}/lib/configure.sh"

# Source all setup modules
# shellcheck source=lib/catalog.sh
source "${ZAPZ_ROOT}/lib/catalog.sh"
source "${ZAPZ_ROOT}/lib/modules/xcode.sh"
source "${ZAPZ_ROOT}/lib/modules/security.sh"
source "${ZAPZ_ROOT}/lib/modules/homebrew.sh"
source "${ZAPZ_ROOT}/lib/modules/git.sh"
source "${ZAPZ_ROOT}/lib/modules/ssh.sh"
source "${ZAPZ_ROOT}/lib/modules/languages.sh"
source "${ZAPZ_ROOT}/lib/modules/node.sh"
source "${ZAPZ_ROOT}/lib/modules/terminal.sh"
source "${ZAPZ_ROOT}/lib/modules/appstore.sh"
source "${ZAPZ_ROOT}/lib/modules/macos.sh"
source "${ZAPZ_ROOT}/lib/modules/schedule.sh"

# Default config file location
DEFAULT_CONFIG="${ZAPZ_ROOT}/config/default.yml"
CUSTOM_CONFIG=""
GIST_URL=""

# Command line arguments
VERBOSE=false
SKIP_MACOS=false
SKIP_SCHEDULE=false
DRY_RUN=false
ASSUME_YES=false

# Usage information; exits with $1 (default 0)
usage() {
    local status="${1:-0}"
    cat << EOF
Usage: zapz [OPTIONS]

Set up a macOS development environment from a YAML config.

Options:
    -n, --dry-run          Show what would happen, change nothing
    -y, --yes              Don't ask for confirmation
    --configure            Answer a few questions to (re)create your config
    -c, --config FILE      Use custom config file
    -g, --gist URL         Use settings from a GitHub Gist raw URL
    --skip-macos           Skip macOS preferences setup
    --skip-schedule        Skip scheduled update setup (alias: --skip-cron)
    --update               Update zapz to the latest version
    -v, --verbose          Enable verbose output
    --version              Show version information
    -h, --help             Show this help message

Examples:
    zapz --dry-run
    zapz --config ~/dotfiles/zapz.yml
    zapz --gist https://gist.githubusercontent.com/user/id/raw/config.yml
EOF
    exit "$status"
}

# Fail with a usage hint when an option is missing its value
require_value() {
    if [[ $# -lt 2 || -z "$2" || "$2" == -* ]]; then
        log_error "Option $1 requires a value"
        usage 1 >&2
    fi
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            --version)
                print_version
                exit 0
                ;;
            --update)
                update_zapz
                exit 0
                ;;
            -n|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -y|--yes)
                ASSUME_YES=true
                shift
                ;;
            --configure)
                configure_and_exit
                ;;
            -c|--config)
                require_value "$@"
                CUSTOM_CONFIG="$2"
                shift 2
                ;;
            -g|--gist)
                require_value "$@"
                GIST_URL="$2"
                shift 2
                ;;
            --skip-macos)
                SKIP_MACOS=true
                shift
                ;;
            --skip-schedule|--skip-cron)
                SKIP_SCHEDULE=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                usage 1 >&2
                ;;
        esac
    done
}

# Version information
print_version() {
    echo "zapz version ${ZAPZ_VERSION}"
    echo "https://github.com/${ZAPZ_REPO_SLUG}"
}

# Pull the latest zapz into the install directory
update_zapz() {
    if [[ ! -d "${ZAPZ_ROOT}/.git" ]]; then
        log_error "zapz at ${ZAPZ_ROOT} is not a git checkout; reinstall to update"
        exit 1
    fi

    local before after latest tag
    before=$(git -C "$ZAPZ_ROOT" rev-parse HEAD)
    log_info "Updating zapz..."

    if git -C "$ZAPZ_ROOT" symbolic-ref -q HEAD >/dev/null; then
        if ! git -C "$ZAPZ_ROOT" pull --ff-only --quiet; then
            log_error "Update failed. Local changes in ${ZAPZ_ROOT} may be blocking it."
            exit 1
        fi
    else
        # Installed at a tag (ZAPZ_REF): move to the newest release tag
        git -C "$ZAPZ_ROOT" fetch --quiet --tags origin
        latest=""
        for tag in $(git -C "$ZAPZ_ROOT" tag -l 'v[0-9]*'); do
            if [[ -z "$latest" ]] || version_gt "$tag" "$latest"; then
                latest="$tag"
            fi
        done
        # Never move backwards: an older tag isn't an update
        if [[ -z "$latest" ]] || ! version_gt "$latest" "$ZAPZ_VERSION"; then
            log_success "zapz is already up to date (${ZAPZ_VERSION})"
            return 0
        fi
        if ! git -C "$ZAPZ_ROOT" checkout --quiet "$latest"; then
            log_error "Update failed. Reinstall with: curl -fsSL https://raw.githubusercontent.com/${ZAPZ_REPO_SLUG}/main/install.sh | bash"
            exit 1
        fi
    fi
    after=$(git -C "$ZAPZ_ROOT" rev-parse HEAD)

    if [[ "$before" == "$after" ]]; then
        log_success "zapz is already up to date (${ZAPZ_VERSION})"
    else
        # Re-read the version from the updated checkout
        log_success "Updated zapz to $(bash "${ZAPZ_ROOT}/setup.sh" --version | head -n1 | awk '{print $NF}')"
    fi
}

# Exit unless running on a supported macOS version
check_platform() {
    if [[ "$(uname)" != "Darwin" ]]; then
        log_error "zapz only works on macOS"
        exit 1
    fi

    local macos_version
    macos_version=$(sw_vers -productVersion)
    if version_gt "$ZAPZ_MIN_MACOS_VERSION" "$macos_version"; then
        log_error "zapz needs macOS ${ZAPZ_MIN_MACOS_VERSION} or later (found ${macos_version})"
        exit 1
    fi
    if version_gt "$ZAPZ_RECOMMENDED_MACOS_VERSION" "$macos_version"; then
        log_warning "Homebrew only fully supports macOS ${ZAPZ_RECOMMENDED_MACOS_VERSION} and later; some packages may need to build from source"
    fi
}

# Re-run the setup wizard to write config/default.yml, then stop
configure_and_exit() {
    ensure_yq
    if ! can_prompt; then
        log_error "--configure asks questions, so it needs a terminal"
        exit 1
    fi
    open_prompt_input
    if [[ -f "$DEFAULT_CONFIG" ]]; then
        printf "\n  This replaces your current config, including any edits you made.\n"
        printf "  It's saved first to %s\n\n" "$(tilde_path "$ZAPZ_BACKUP_DIR")"
        if ! confirm "  Replace your config?" N; then
            printf "  Nothing was changed.\n"
            exit 0
        fi
    fi
    run_config_wizard "$DEFAULT_CONFIG"
    printf "\n  Next: run ${BOLD}zapz${NC} to preview and apply it.\n"
    exit 0
}

# Ask for the password once, up front, and keep sudo's timestamp fresh so
# nothing later stops to ask again while you're away
start_admin_session() {
    # Without a terminal there's no one to type a password
    if [[ -z "${ZAPZ_PROMPT_FD:-}" ]]; then
        if sudo -n true 2>/dev/null; then
            return 0
        fi
        log_error "Homebrew and apps need administrator access, and there's no terminal to ask for a password."
        log_info "Run zapz in a terminal, or allow passwordless sudo for this account."
        exit 1
    fi
    printf "\n  zapz needs your Mac password for installs and a few system settings.\n"
    printf "  It asks once now, so the rest can run without you.\n"
    if ! sudo -v; then
        log_error "Couldn't get administrator access. zapz needs an admin account."
        exit 1
    fi
    # Detached from the terminal so it can't hold zapz's output open, and it
    # stops its own sleep when told to exit
    (
        trap 'kill "$sleeper" 2>/dev/null; exit 0' TERM
        while sudo -n true 2>/dev/null && kill -0 "$$" 2>/dev/null; do
            sleep 50 &
            sleeper=$!
            wait "$sleeper"
        done
    ) < /dev/null > /dev/null 2>&1 &
    ZAPZ_SUDO_KEEPALIVE_PID=$!
}

cleanup() {
    rm -f "${ZAPZ_GIST_CONFIG:-}" "${ZAPZ_DRY_RUN_CONFIG:-}"
    [[ -z "${ZAPZ_SUDO_KEEPALIVE_PID:-}" ]] || kill "$ZAPZ_SUDO_KEEPALIVE_PID" 2>/dev/null || true
}

print_banner() {
    local arch="Intel"
    [[ "$(uname -m)" == arm64 ]] && arch="Apple Silicon"
    printf "\n  ${BOLD}⚡ zapz %s${NC} ${DIM}· macOS %s · %s${NC}\n" \
        "$ZAPZ_VERSION" "$(sw_vers -productVersion)" "$arch"
}

main() {
    check_platform
    trap cleanup EXIT

    ensure_yq
    # A dry run before any config exists previews the recommended setup
    # without saving it
    if [[ "$DRY_RUN" == true && -z "$CUSTOM_CONFIG" && -z "$GIST_URL" && ! -f "$DEFAULT_CONFIG" ]]; then
        ZAPZ_DRY_RUN_CONFIG=$(mktemp)
        write_default_config "$ZAPZ_DRY_RUN_CONFIG"
        CUSTOM_CONFIG="$ZAPZ_DRY_RUN_CONFIG"
    fi
    load_configuration
    validate_configuration

    print_banner
    show_plan

    if [[ "$DRY_RUN" == true ]]; then
        printf "\n  Dry run: nothing was changed. Run ${BOLD}zapz${NC} to apply.\n"
        exit 0
    fi

    if can_prompt; then
        open_prompt_input
    fi
    if [[ "$ASSUME_YES" != true ]]; then
        if [[ -z "${ZAPZ_PROMPT_FD:-}" ]]; then
            log_error "There's no terminal to confirm with. Run with --yes to continue without asking."
            exit 1
        fi
        printf "\n"
        if ! confirm "  Continue?" Y; then
            printf "  Nothing was changed.\n"
            exit 0
        fi
    fi

    # Every question up front, so the long part can run unattended
    [[ -z "${ZAPZ_PROMPT_FD:-}" ]] || ask_git_identity
    if [[ "$PLAN_NEEDS_ADMIN" == true ]]; then
        start_admin_session
    fi

    ensure_log_file
    local start=$SECONDS

    # The steps that apply to this config, in order
    local steps=(install_xcode_tools)
    if config_enabled '.security.touch_id_sudo' || config_enabled '.security.firewall' \
            || config_enabled '.security.filevault_check'; then
        steps+=(setup_security)
    fi
    steps+=(setup_git setup_ssh setup_homebrew)
    [[ -z "$(config_list '.languages.tools')" ]] || steps+=(setup_languages)
    # Older configs set Node.js up with nvm (node.versions)
    [[ -z "$(config_list '.node.versions')" ]] || steps+=(setup_node)
    steps+=(setup_terminal_shell)
    [[ "$(yq e '.apps.app_store // [] | length' "$CONFIG_FILE")" == 0 ]] || steps+=(setup_app_store)
    [[ "$SKIP_MACOS" == true ]] || steps+=(setup_macos_preferences)
    [[ "$SKIP_SCHEDULE" == true ]] || steps+=(setup_scheduled_updates)
    steps+=(setup_github)
    ZAPZ_STEP_TOTAL=${#steps[@]}

    # Things from the config only the user can do (downloads, sign-ins)
    local title url cmd note
    while IFS=$'\t' read -r title url cmd note; do
        [[ -n "$title" ]] || continue
        add_checklist "$title" "${url#-}" "${cmd#-}" "${note#-}"
    done < <(yq e '(.checklist // [])[] | [.title, (.url // "-"), (.command // "-"), (.note // "-")] | @tsv' "$CONFIG_FILE")

    local step
    for step in "${steps[@]}"; do
        "$step"
    done

    add_next_step "Open a new terminal (or run: exec \$SHELL -l) to start using everything"
    local elapsed=$((SECONDS - start))
    ui_summary "$elapsed"

    if ((${#ZAPZ_FAILED[@]} > 0)); then
        notify "Setup finished with ${#ZAPZ_FAILED[@]} problem(s)"
        exit 1
    fi
    ((elapsed < 60)) || notify "Your Mac is ready"
}

# Run only when executed, so tests can source this file
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    parse_arguments "$@"
    main
fi
