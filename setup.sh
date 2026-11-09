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
    --update [TARGET]      Update zapz to the latest release, or to TARGET:
                           a version (v0.3.0), a branch to test, or "latest"
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
                # Optional target: a version, a branch, or "latest"
                if [[ $# -gt 1 && "$2" != -* ]]; then
                    update_zapz "$2"
                else
                    update_zapz
                fi
                exit 0
                ;;
            --after-update)
                require_value "$@"
                after_update "$2"
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

# Newest release tag in the checkout (vX.Y.Z), or nothing
_newest_release_tag() {
    local tag latest=""
    for tag in $(git -C "$ZAPZ_ROOT" tag -l 'v[0-9]*'); do
        if [[ -z "$latest" ]] || version_gt "$tag" "$latest"; then
            latest="$tag"
        fi
    done
    printf '%s' "$latest"
}

# Update the zapz checkout.
#   zapz --update            newest release; a branch you chose on purpose
#                            (like main) keeps following that branch, and
#                            one that's gone from GitHub returns to releases
#   zapz --update latest     newest release, even from main
#   zapz --update v0.3.0     that release (the only way to go back)
#   zapz --update <branch>   follow a branch, e.g. to test a fix
update_zapz() {
    local target="${1:-}" root="$ZAPZ_ROOT"
    if [[ ! -d "$root/.git" ]]; then
        log_error "zapz at $(tilde_path "$root") is not a git checkout; reinstall to update:"
        log_info "curl -fsSL https://raw.githubusercontent.com/${ZAPZ_REPO_SLUG}/main/install.sh | bash"
        exit 1
    fi
    if [[ -n "$(git -C "$root" status --porcelain --untracked-files=no)" ]]; then
        log_error "zapz has local changes in $(tilde_path "$root"), so it can't update over them."
        log_info "To set them aside and update: git -C $(tilde_path "$root") stash && zapz --update"
        exit 1
    fi

    log_info "Checking for updates..."
    if ! git -C "$root" fetch --quiet --tags --prune origin; then
        log_error "Couldn't reach GitHub to check for updates. Check your internet connection and try again."
        exit 1
    fi

    local before latest branch dest="" follow=""
    before=$(git -C "$root" rev-parse HEAD)
    latest=$(_newest_release_tag)
    branch=$(git -C "$root" symbolic-ref -q --short HEAD || true)

    case "$target" in
        "")
            if [[ -n "$branch" ]] && git -C "$root" show-ref -q --verify "refs/remotes/origin/$branch"; then
                follow="$branch"
            elif [[ -n "$branch" ]]; then
                log_warning "The $branch branch is no longer on GitHub; returning to the latest release."
                dest="$latest"
            elif [[ -n "$latest" ]] && version_gt "$latest" "$ZAPZ_VERSION"; then
                dest="$latest"
            else
                log_success "zapz is already up to date (${ZAPZ_VERSION})"
                return 0
            fi
            ;;
        latest|release)
            dest="$latest"
            ;;
        *)
            if git -C "$root" show-ref -q --verify "refs/remotes/origin/$target"; then
                follow="$target"
            elif git -C "$root" show-ref -q --verify "refs/tags/v${target#v}"; then
                dest="v${target#v}"
            else
                log_error "There's no zapz release or branch called '$target'."
                [[ -z "$latest" ]] || log_info "The latest release is $latest. Run: zapz --update"
                exit 1
            fi
            ;;
    esac

    if [[ -n "$follow" ]]; then
        if [[ "$follow" == "$branch" ]]; then
            if ! git -C "$root" merge --ff-only --quiet "origin/$follow"; then
                log_error "Couldn't update the $follow branch: it has changes that aren't on GitHub."
                log_info "To return to the latest release instead: zapz --update latest"
                exit 1
            fi
        else
            git -C "$root" checkout --quiet -B "$follow" "origin/$follow"
            git -C "$root" branch --quiet --set-upstream-to="origin/$follow" "$follow" 2>/dev/null || true
        fi
    elif [[ -n "$dest" ]]; then
        git -C "$root" checkout --quiet "$dest"
    else
        # No releases at all: the default branch is the newest zapz
        local default_ref
        default_ref=$(git -C "$root" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null || echo origin/main)
        git -C "$root" checkout --quiet -B "${default_ref#origin/}" "$default_ref"
    fi

    if [[ "$(git -C "$root" rev-parse HEAD)" == "$before" ]]; then
        log_success "zapz is already up to date (${ZAPZ_VERSION}, $(_describe_checkout))"
        return 0
    fi
    # Finish with the updated code, so new shell setup and notes apply
    "$BASH" "$root/setup.sh" --after-update "$ZAPZ_VERSION"
}

# Where the checkout is: a release tag, or a branch and commit
_describe_checkout() {
    local ref
    if ref=$(git -C "$ZAPZ_ROOT" describe --tags --exact-match 2>/dev/null); then
        printf '%s' "$ref"
    elif ref=$(git -C "$ZAPZ_ROOT" symbolic-ref -q --short HEAD); then
        printf '%s branch, %s' "$ref" "$(git -C "$ZAPZ_ROOT" rev-parse --short HEAD)"
    else
        git -C "$ZAPZ_ROOT" rev-parse --short HEAD
    fi
}

# Run by `zapz --update` from the new code: refresh the shell setup and say
# what changed since version $1
after_update() {
    local from="$1"
    install_cli_command "$ZAPZ_ROOT"
    log_success "Updated zapz ${from} → ${ZAPZ_VERSION} ($(_describe_checkout))"
    if version_gt "$ZAPZ_VERSION" "$from"; then
        local notes
        notes=$(changelog_since "$ZAPZ_ROOT/CHANGELOG.md" "$from")
        if [[ -n "$notes" ]]; then
            printf "\n  ${BOLD}What's new${NC}\n"
            printf '%s\n' "$notes" | head -n 40 | sed 's/^/  /'
            if (($(printf '%s\n' "$notes" | wc -l) > 40)); then
                printf '  …and more: %s/blob/main/CHANGELOG.md\n' "https://github.com/${ZAPZ_REPO_SLUG}"
            fi
        fi
    fi
    if [[ "${ZAPZ_BLOCK_CHANGED:-false}" == true ]]; then
        log_info "Your shell setup changed; open a new terminal to pick it up."
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

# Homebrew 7 resets sudo's saved password the first time it needs sudo,
# which would make every later installer ask again. This tells it the check
# is already done, so the password given to zapz stays valid.
keep_sudo_for_homebrew() {
    export HOMEBREW_SUDO_CHECKED=1
}

# Ask for the password once, up front, and keep sudo's timestamp fresh so
# nothing later stops to ask again while you're away
start_admin_session() {
    # Without a terminal there's no one to type a password
    if [[ -z "${ZAPZ_PROMPT_FD:-}" ]]; then
        if sudo -n true 2>/dev/null; then
            keep_sudo_for_homebrew
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
    keep_sudo_for_homebrew
    # Installers that need sudo without a terminal (Homebrew's pkg installs)
    # ask with a Mac password dialog instead of failing or waiting unseen.
    # Not over SSH, where no one can see a dialog.
    if [[ -z "${SSH_CONNECTION:-}" ]] && command -v osascript >/dev/null 2>&1; then
        export SUDO_ASKPASS="$ZAPZ_ROOT/lib/askpass.sh"
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
