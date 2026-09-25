#!/usr/bin/env bash

# Install zapz:
#   curl -fsSL https://raw.githubusercontent.com/corbanb/zapz/main/install.sh | bash
#
# Environment overrides:
#   ZAPZ_HOME    install location (default: ~/.local/share/zapz)
#   ZAPZ_REPO    git URL to clone (default: https://github.com/corbanb/zapz.git)
#   ZAPZ_REF     branch or tag to install (default: the repo's default branch)
#   ZAPZ_SOURCE  local directory to copy instead of cloning (used by CI)

set -euo pipefail

ZAPZ_HOME="${ZAPZ_HOME:-$HOME/.local/share/zapz}"
ZAPZ_REPO="${ZAPZ_REPO:-https://github.com/corbanb/zapz.git}"
ZAPZ_REF="${ZAPZ_REF:-}"
ZAPZ_SOURCE="${ZAPZ_SOURCE:-}"
BIN_DIR="$HOME/.local/bin"

# Minimal output helpers until the repo (and lib/logging.sh) is available
print_info() { printf '\033[0;34mINFO: %s\033[0m\n' "$1"; }
print_error() { printf '\033[0;31mERROR: %s\033[0m\n' "$1" >&2; }

if [[ "$(uname)" != "Darwin" ]]; then
    print_error "zapz only works on macOS"
    exit 1
fi

# On a fresh Mac, /usr/bin/git is a stub that fails until the
# Xcode Command Line Tools are installed
if ! git --version >/dev/null 2>&1; then
    print_error "git is required to install zapz"
    print_info "Install the Xcode Command Line Tools first: xcode-select --install"
    exit 1
fi

# Fetch or update the code
if [[ -n "$ZAPZ_SOURCE" ]]; then
    print_info "Copying zapz from $ZAPZ_SOURCE..."
    mkdir -p "$ZAPZ_HOME"
    # Skip .git (read-only objects break re-copying) and the user's config
    tar -C "$ZAPZ_SOURCE" --exclude=./.git --exclude=./config/default.yml -cf - . \
        | tar -C "$ZAPZ_HOME" -xf -
elif [[ -d "$ZAPZ_HOME/.git" ]]; then
    print_info "Updating existing installation in $ZAPZ_HOME..."
    if [[ -n "$ZAPZ_REF" ]]; then
        git -C "$ZAPZ_HOME" fetch --quiet origin "$ZAPZ_REF"
        git -C "$ZAPZ_HOME" checkout --quiet FETCH_HEAD
    else
        git -C "$ZAPZ_HOME" pull --ff-only --quiet
    fi
elif [[ -e "$ZAPZ_HOME" && -n "$(ls -A "$ZAPZ_HOME")" ]]; then
    print_error "$ZAPZ_HOME exists and is not a zapz checkout; move it or set ZAPZ_HOME"
    exit 1
else
    print_info "Installing zapz to $ZAPZ_HOME..."
    mkdir -p "$(dirname "$ZAPZ_HOME")"
    git clone --quiet ${ZAPZ_REF:+--branch "$ZAPZ_REF"} "$ZAPZ_REPO" "$ZAPZ_HOME"
fi

# shellcheck source=lib/logging.sh
source "$ZAPZ_HOME/lib/logging.sh"
# shellcheck source=lib/utils.sh
source "$ZAPZ_HOME/lib/utils.sh"

# Create the user's config from the example on first install
if [[ ! -f "$ZAPZ_HOME/config/default.yml" ]]; then
    log_info "Creating config at $ZAPZ_HOME/config/default.yml"
    cp "$ZAPZ_HOME/config/default.yml.example" "$ZAPZ_HOME/config/default.yml"
fi

# Put the `zapz` command on PATH
mkdir -p "$BIN_DIR"
ln -sf "$ZAPZ_HOME/setup.sh" "$BIN_DIR/zapz"

# macOS Terminal starts login shells, which read ~/.bash_profile, not ~/.bashrc
case "${SHELL:-}" in
    */bash) shell_rc="$HOME/.bash_profile" ;;
    *) shell_rc="$HOME/.zshrc" ;;
esac

write_managed_block "$shell_rc" "cli" "case \":\$PATH:\" in
    *\":\$HOME/.local/bin:\"*) ;;
    *) export PATH=\"\$HOME/.local/bin:\$PATH\" ;;
esac
export ZAPZ_HOME=\"$ZAPZ_HOME\"
[ -f \"\$ZAPZ_HOME/lib/check_update.sh\" ] && . \"\$ZAPZ_HOME/lib/check_update.sh\""

log_success "Installation complete!"
log_info "Review your config: $ZAPZ_HOME/config/default.yml"
log_info "Then open a new terminal and run: zapz"
