#!/usr/bin/env bash

# Install zapz:
#   curl -fsSL https://raw.githubusercontent.com/corbanb/zapz/main/install.sh | bash
#
# Environment overrides:
#   ZAPZ_HOME    install location (default: ~/.local/share/zapz)
#   ZAPZ_REPO    git URL to clone (default: https://github.com/corbanb/zapz.git)
#   ZAPZ_REF     branch or tag to install (default: the latest release, or the
#                default branch if there is no release yet)
#   ZAPZ_SOURCE  local directory to copy instead of cloning (used by CI)

set -euo pipefail

ZAPZ_HOME="${ZAPZ_HOME:-$HOME/.local/share/zapz}"
ZAPZ_REPO="${ZAPZ_REPO:-https://github.com/corbanb/zapz.git}"
ZAPZ_REF="${ZAPZ_REF:-}"
ZAPZ_SOURCE="${ZAPZ_SOURCE:-}"

# Minimal output helpers until the repo (and lib/logging.sh) is available
print_info() { printf '  \033[0;34m➜\033[0m %s\n' "$1"; }
print_error() { printf '  \033[0;31m✗ %s\033[0m\n' "$1" >&2; }
print_warning() { printf '  \033[0;33m!\033[0m %s\n' "$1" >&2; }

if [[ "$(uname)" != "Darwin" ]]; then
    print_error "zapz only works on macOS"
    exit 1
fi

# A fresh Mac has no git until the Xcode Command Line Tools are installed.
# Start that install (Apple's dialog) and wait, so one command works on a
# brand-new machine.
if ! xcode-select -p >/dev/null 2>&1; then
    print_info "Installing the Xcode Command Line Tools (needed for git)..."
    xcode-select --install >/dev/null 2>&1 || true
    print_info "Click Install in the dialog that opened. This can take several minutes."
    waited=0
    timeout="${ZAPZ_XCODE_TIMEOUT:-1800}"
    until xcode-select -p >/dev/null 2>&1; do
        if ((waited >= timeout)); then
            print_error "The Xcode Command Line Tools still aren't installed"
            print_info "Run 'xcode-select --install', finish the installer, then run this command again"
            exit 1
        fi
        sleep 5
        waited=$((waited + 5))
    done
fi

if ! git --version >/dev/null 2>&1; then
    print_error "git is required to install zapz, but it isn't working"
    print_info "Try reinstalling the Xcode Command Line Tools: xcode-select --install"
    exit 1
fi

printf '\n  \033[1m⚡ Installing zapz\033[0m\n\n'

# Install the latest release by default: a tested version, not whatever is
# on the main branch today. ZAPZ_REF=main opts into the latest code.
if [[ -z "$ZAPZ_REF" && -z "$ZAPZ_SOURCE" && "$ZAPZ_REPO" == "https://github.com/corbanb/zapz.git" ]]; then
    ZAPZ_REF=$(curl -fsS --max-time 10 --retry 3 --retry-all-errors --retry-delay 2 \
            https://api.github.com/repos/corbanb/zapz/releases/latest 2>/dev/null \
        | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' | head -n1) || ZAPZ_REF=""
    if [[ -z "$ZAPZ_REF" ]]; then
        print_warning "Couldn't look up the latest release on GitHub; installing the newest code from main instead"
    fi
fi

# Fetch or update the code
if [[ -n "$ZAPZ_SOURCE" ]]; then
    print_info "Copying zapz from $ZAPZ_SOURCE"
    mkdir -p "$ZAPZ_HOME"
    # Skip .git (read-only objects break re-copying) and the user's config
    tar -C "$ZAPZ_SOURCE" --exclude=./.git --exclude=./config/default.yml -cf - . \
        | tar -C "$ZAPZ_HOME" -xf -
elif [[ -d "$ZAPZ_HOME/.git" ]]; then
    print_info "Updating existing installation in $ZAPZ_HOME..."
    if [[ -n "$ZAPZ_REF" ]]; then
        git -C "$ZAPZ_HOME" fetch --quiet origin "$ZAPZ_REF"
        if git -C "$ZAPZ_HOME" ls-remote --exit-code --heads origin "$ZAPZ_REF" >/dev/null 2>&1; then
            # A branch: stay on it so `zapz --update` can pull
            git -C "$ZAPZ_HOME" checkout --quiet -B "$ZAPZ_REF" FETCH_HEAD
        else
            git -C "$ZAPZ_HOME" checkout --quiet FETCH_HEAD
        fi
    elif git -C "$ZAPZ_HOME" symbolic-ref -q HEAD >/dev/null; then
        git -C "$ZAPZ_HOME" pull --ff-only --quiet
    else
        # A previous ZAPZ_REF install left a detached HEAD; return to the
        # default branch
        git -C "$ZAPZ_HOME" fetch --quiet origin
        default_ref=$(git -C "$ZAPZ_HOME" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null || echo origin/main)
        git -C "$ZAPZ_HOME" checkout --quiet -B "${default_ref#origin/}" "$default_ref"
    fi
elif [[ -e "$ZAPZ_HOME" && -n "$(ls -A "$ZAPZ_HOME")" ]]; then
    print_error "$ZAPZ_HOME exists and is not a zapz checkout; move it or set ZAPZ_HOME"
    exit 1
else
    print_info "Installing zapz to $ZAPZ_HOME..."
    mkdir -p "$(dirname "$ZAPZ_HOME")"
    git clone --quiet ${ZAPZ_REF:+--branch "$ZAPZ_REF"} "$ZAPZ_REPO" "$ZAPZ_HOME"
fi

ZAPZ_ROOT="$ZAPZ_HOME"
# shellcheck source=lib/version.sh
source "$ZAPZ_HOME/lib/version.sh"
# shellcheck source=lib/logging.sh
source "$ZAPZ_HOME/lib/logging.sh"
# shellcheck source=lib/utils.sh
source "$ZAPZ_HOME/lib/utils.sh"
# shellcheck source=lib/catalog.sh
source "$ZAPZ_HOME/lib/catalog.sh"
# shellcheck source=lib/configure.sh
source "$ZAPZ_HOME/lib/configure.sh"

# Put the `zapz` command on PATH first, so a failed download below still
# leaves a command to run again
install_cli_command "$ZAPZ_HOME"

ensure_yq
log_success "zapz ${ZAPZ_VERSION} is in $(tilde_path "$ZAPZ_HOME")"

# First install: answer a few questions instead of editing YAML (or, with
# no terminal to ask, start from the example config)
config="$ZAPZ_HOME/config/default.yml"
asked=false
if [[ -f "$config" ]]; then
    log_success "Keeping your config: $(tilde_path "$config")"
elif can_prompt; then
    open_prompt_input
    run_config_wizard "$config"
    asked=true
else
    # No one to ask: the essentials and every recommended choice
    write_default_config "$config"
    log_success "Created a recommended config: $(tilde_path "$config")"
fi

if [[ "$asked" == true ]]; then
    printf "\n"
    if confirm "  Preview and run setup now?" Y; then
        # Hand the open terminal input to setup so answers carry over
        export ZAPZ_PROMPT_FD
        exec "$ZAPZ_HOME/setup.sh" <&"$ZAPZ_PROMPT_FD"
    fi
fi

printf "\n  Installed. Open a new terminal, then run ${BOLD}zapz${NC} to preview and apply your setup.\n"
printf "  ${DIM}Your config: %s · change it with zapz --configure${NC}\n" "$(tilde_path "$config")"
