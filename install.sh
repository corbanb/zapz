#!/usr/bin/env bash

# Installation script for macOS setup tool
set -euo pipefail

# Default installation directory
DEFAULT_INSTALL_DIR="$HOME/.local/bin/mac-setup"
INSTALL_DIR="${INSTALL_DIR:-$DEFAULT_INSTALL_DIR}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Print with color
print_info() { printf "${BLUE}INFO: %s${NC}\n" "$1"; }
print_success() { printf "${GREEN}SUCCESS: %s${NC}\n" "$1"; }
print_error() { printf "${RED}ERROR: %s${NC}\n" "$1" >&2; }

# Only git is needed to install; setup.sh installs Homebrew, yq, etc. itself
check_dependencies() {
    # On a fresh Mac, /usr/bin/git is a stub that fails until the
    # Xcode Command Line Tools are installed
    if ! git --version >/dev/null 2>&1; then
        print_error "git is required to install zapz"
        print_info "Install the Xcode Command Line Tools first: xcode-select --install"
        exit 1
    fi
}

# Check if running on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    print_error "This tool only works on macOS"
    exit 1
fi

# Check and install dependencies
check_dependencies

# Create installation directory
mkdir -p "$INSTALL_DIR"

# Clone repository
if [[ "${MOCK_INSTALL:-false}" == "true" ]]; then
    print_info "Running in test mode..."
elif [[ -d "$INSTALL_DIR/.git" ]]; then
    print_info "Updating existing installation..."
    git -C "$INSTALL_DIR" pull
else
    print_info "Installing mac-setup..."
    git clone https://github.com/corbanb/zapz.git "$INSTALL_DIR"
fi

# Copy example config if default doesn't exist (after clone)
if [[ -f "$INSTALL_DIR/config/default.yml.example" ]] && [[ ! -f "$INSTALL_DIR/config/default.yml" ]]; then
    print_info "Creating default config from example..."
    cp "$INSTALL_DIR/config/default.yml.example" "$INSTALL_DIR/config/default.yml"
fi

# Copy example secrets if .secrets doesn't exist
if [[ -f "$INSTALL_DIR/.secrets.example" ]] && [[ ! -f "$HOME/.local/bin/.secrets" ]]; then
    cp "$INSTALL_DIR/.secrets.example" "$HOME/.local/bin/.secrets"
    chmod 600 "$HOME/.local/bin/.secrets"  # Secure file permissions
    print_info "Created .secrets file at $HOME/.local/bin/.secrets"
    print_info "Please update it with your GitHub token"
fi

# Make all scripts executable
chmod +x "$INSTALL_DIR/setup.sh"
chmod +x "$INSTALL_DIR/test/test.sh"
chmod +x "$INSTALL_DIR/lib/modules/"*.sh

# Verify permissions
if ! [[ -x "$INSTALL_DIR/setup.sh" ]] || ! [[ -x "$INSTALL_DIR/test/test.sh" ]]; then
    print_error "Failed to set executable permissions"
    print_info "Try running: chmod +x setup.sh test/test.sh lib/modules/*.sh"
    exit 1
fi

# Create symlink in PATH
SYMLINK_PATH="$HOME/.local/bin/zapz"
mkdir -p "$(dirname "$SYMLINK_PATH")" || true
ln -sf "$INSTALL_DIR/setup.sh" "$SYMLINK_PATH"

# Add to PATH if needed
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    SHELL_RC="$HOME/.zshrc"
    touch "$SHELL_RC"  # Ensure file exists
    [[ "$SHELL" == */bash ]] && SHELL_RC="$HOME/.bashrc"

    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_RC"

    # Add update check to shell RC
    cat >> "$SHELL_RC" << 'EOF'

# zapz update check
if [[ -f "$HOME/.local/bin/mac-setup/lib/check_update.sh" ]]; then
    source "$HOME/.local/bin/mac-setup/lib/check_update.sh"
fi
EOF

    print_info "Added ~/.local/bin to PATH in $SHELL_RC"
fi

print_success "Installation complete!"
print_info "Run 'zapz --help' to get started"
print_info "Source your shell config or restart your terminal to use the 'zapz' command"
