#!/bin/bash

# Routine package updates, run on a schedule by launchd (see
# lib/modules/schedule.sh). launchd starts jobs with a minimal PATH, so this
# script finds Homebrew and nvm itself.

set -uo pipefail

notify() {
    osascript -e "display notification \"$1\" with title \"zapz\"" >/dev/null 2>&1 || true
}

for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [[ -x "$brew_bin" ]]; then
        eval "$("$brew_bin" shellenv)"
        break
    fi
done

echo "=== zapz update started at $(date) ==="
failed=()

if command -v brew >/dev/null 2>&1; then
    echo "Updating Homebrew..."
    brew update && brew upgrade && brew cleanup || failed+=("Homebrew")
else
    echo "Homebrew not found; skipping"
fi

export NVM_DIR="$HOME/.nvm"
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    # shellcheck disable=SC1091
    set +u; . "$NVM_DIR/nvm.sh"; set -u
    if command -v npm >/dev/null 2>&1; then
        echo "Updating global npm packages..."
        npm update -g || failed+=("npm")
    fi
fi

if command -v mas >/dev/null 2>&1; then
    echo "Updating App Store apps..."
    mas upgrade || failed+=("App Store")
fi

echo "=== zapz update finished at $(date) ==="

if ((${#failed[@]} > 0)); then
    notify "Updates failed for: ${failed[*]}. See ~/Library/Logs/zapz/update.log"
    exit 1
fi
notify "Scheduled updates completed"
