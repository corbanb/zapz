#!/usr/bin/env bash

# macOS Development Environment Setup Tool
# Version: 1.0.0
# Author: Your Name
# License: MIT

# Strict mode
set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source utilities and modules
source "${SCRIPT_DIR}/lib/version.sh"
source "${SCRIPT_DIR}/lib/utils.sh"
source "${SCRIPT_DIR}/lib/logging.sh"

# Source all setup modules
source "${SCRIPT_DIR}/lib/modules/xcode.sh"
source "${SCRIPT_DIR}/lib/modules/homebrew.sh"
source "${SCRIPT_DIR}/lib/modules/git.sh"
source "${SCRIPT_DIR}/lib/modules/ssh.sh"
source "${SCRIPT_DIR}/lib/modules/node.sh"
source "${SCRIPT_DIR}/lib/modules/macos.sh"
source "${SCRIPT_DIR}/lib/modules/cron.sh"

# Default config file location
DEFAULT_CONFIG="${SCRIPT_DIR}/config/default.yml"
CUSTOM_CONFIG=""
GIST_URL=""

# Command line arguments
VERBOSE=false
FORCE=false
SKIP_MACOS=false
SKIP_CRON=false

# Usage information
usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

A zero-dependency macOS development environment setup tool.

Options:
    -h, --help              Show this help message
    -v, --verbose          Enable verbose output
    --version             Show version information
    --update              Update zapz to the latest version
    -f, --force            Force reinstallation of components
    -c, --config FILE      Use custom config file
    -g, --gist URL         Use settings from a GitHub Gist URL
    --skip-macos          Skip macOS preferences setup
    --skip-cron           Skip cron job setup
    
Example:
    ./setup.sh --verbose --config custom.yml
    ./setup.sh --gist https://gist.raw.githubusercontent.com/user/id/file
EOF
    exit 0
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
                check_for_updates
                exit 0
                ;;
            -f|--force)
                FORCE=true
                shift
                ;;
            -c|--config)
                CUSTOM_CONFIG="$2"
                shift 2
                ;;
            -g|--gist)
                GIST_URL="$2"
                shift 2
                ;;
            --skip-macos)
                SKIP_MACOS=true
                shift
                ;;
            --skip-cron)
                SKIP_CRON=true
                shift
                ;;
            *)
                error "Unknown option: $1"
                usage
                ;;
        esac
    done
}

# Version information
print_version() {
    echo "zapz version ${ZAPZ_VERSION}"
    echo "https://github.com/corbanb/zapz"
}

check_for_updates() {
    if [[ "$VERBOSE" == true ]]; then
        log_info "Checking for updates..."
    fi
    
    # Get latest version from GitHub releases
    local latest_version
    latest_version=$(curl -s https://api.github.com/repos/corbanb/zapz/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    
    if [[ "$latest_version" != "v${ZAPZ_VERSION}" ]]; then
        log_warning "A new version of zapz is available: ${latest_version}"
        log_info "Update with: zapz --update"
        log_info "Or visit: ${ZAPZ_RELEASE_URL}"
    fi
}

# Main setup function
main() {
    # Print welcome message
    log_header "Starting macOS Development Environment Setup"
    
    # Check if running on macOS
    if [[ "$(uname)" != "Darwin" ]]; then
        error "This script only works on macOS"
        exit 1
    fi

    # Load configuration
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
    
    if [[ "$SKIP_CRON" != "true" ]]; then
        setup_cron_jobs
    fi
    
    log_success "Setup completed successfully!"
    
    # Final instructions
    if [[ -f "$HOME/.ssh/id_ed25519.pub" ]]; then
        log_info "Don't forget to add your SSH key to GitHub: https://github.com/settings/keys"
        log_info "The key has been copied to your clipboard."
    fi
}

# Initialize
parse_arguments "$@"
main 