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

# Source all setup modules
source "${ZAPZ_ROOT}/lib/modules/xcode.sh"
source "${ZAPZ_ROOT}/lib/modules/homebrew.sh"
source "${ZAPZ_ROOT}/lib/modules/git.sh"
source "${ZAPZ_ROOT}/lib/modules/ssh.sh"
source "${ZAPZ_ROOT}/lib/modules/node.sh"
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

# Usage information; exits with $1 (default 0)
usage() {
    local status="${1:-0}"
    cat << EOF
Usage: zapz [OPTIONS]

Set up a macOS development environment from a YAML config.

Options:
    -h, --help             Show this help message
    -v, --verbose          Enable verbose output
    --version              Show version information
    --update               Update zapz to the latest version
    -c, --config FILE      Use custom config file
    -g, --gist URL         Use settings from a GitHub Gist raw URL
    --skip-macos           Skip macOS preferences setup
    --skip-schedule        Skip scheduled update setup (alias: --skip-cron)

Examples:
    zapz --verbose --config custom.yml
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

    local before after
    before=$(git -C "$ZAPZ_ROOT" rev-parse HEAD)
    log_info "Updating zapz..."
    if ! git -C "$ZAPZ_ROOT" pull --ff-only --quiet; then
        log_error "Update failed. Local changes in ${ZAPZ_ROOT} may be blocking it."
        exit 1
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
}

cleanup() {
    rm -f "${ZAPZ_GIST_CONFIG:-}"
}

# Main setup function
main() {
    log_header "Starting macOS Development Environment Setup"

    check_platform
    trap cleanup EXIT

    load_configuration

    # Run setup modules
    install_xcode_tools
    setup_homebrew
    setup_git
    setup_ssh
    setup_node

    # Optional setups
    if [[ "$SKIP_MACOS" != "true" ]]; then
        setup_macos_preferences
    fi

    if [[ "$SKIP_SCHEDULE" != "true" ]]; then
        setup_scheduled_updates
    fi

    log_success "Setup completed successfully!"
    log_info "Open a new terminal to pick up PATH and shell changes."
}

# Run only when executed, so tests can source this file
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    parse_arguments "$@"
    main
fi
