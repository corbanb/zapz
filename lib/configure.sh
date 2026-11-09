#!/usr/bin/env bash

# The setup wizard: a few questions that write config/default.yml from a
# preset, so new users never have to edit YAML. Used by install.sh and
# `zapz --configure`. Needs open_prompt_input to have been called.

# file|title|summary
ZAPZ_PRESETS=(
    "essentials|Essentials|command-line tools, VS Code, iTerm2"
    "webdev|Web development|Essentials + Node.js, Bun, Deno, Docker Desktop, 1Password"
    "minimal|Minimal|command-line tools only"
)
ZAPZ_DEFAULT_PRESET=2

# Usage: run_config_wizard <config file to write>
run_config_wizard() {
    local dest="$1" name email choice i entry file title summary tmp
    local apply_macos=true updates=true

    printf "\n  ${BOLD}Let's set up your Mac.${NC} A few questions, then you'll see\n"
    printf "  exactly what will happen before anything changes.\n\n"

    name=$(ask "  Your name (for git commits)" "$(git config --global --get user.name 2>/dev/null || true)")
    email=$(ask "  Your email (for git commits)" "$(git config --global --get user.email 2>/dev/null || true)")

    printf "\n  ${BOLD}What should zapz install?${NC}\n"
    i=1
    for entry in "${ZAPZ_PRESETS[@]}"; do
        IFS='|' read -r file title summary <<< "$entry"
        printf "    %d) %-16s ${DIM}%s${NC}\n" "$i" "$title" "$summary"
        i=$((i + 1))
    done
    while true; do
        choice=$(ask "  Choose 1-${#ZAPZ_PRESETS[@]}" "$ZAPZ_DEFAULT_PRESET")
        if [[ "$choice" =~ ^[0-9]+$ ]] && ((choice >= 1 && choice <= ${#ZAPZ_PRESETS[@]})); then
            break
        fi
        printf "  Please enter a number from 1 to %d.\n" "${#ZAPZ_PRESETS[@]}" >&2
    done
    entry="${ZAPZ_PRESETS[choice - 1]}"
    IFS='|' read -r file title summary <<< "$entry"

    printf "\n"
    confirm "  Apply recommended macOS settings (Dock, Finder, key repeat)?" Y || apply_macos=false
    confirm "  Keep your apps and tools updated automatically (Mondays at 09:00)?" Y || updates=false

    tmp=$(mktemp)
    {
        printf '# Created by the zapz setup wizard (%s preset).\n' "$title"
        printf '# Edit freely; every option is in config/default.yml.example.\n'
        printf '# Re-run the wizard with: zapz --configure\n'
        cat "$ZAPZ_ROOT/config/presets/$file.yml"
    } > "$tmp"

    if [[ -n "$name" ]]; then
        ZAPZ_W_VALUE="$name" yq -i '.git.user.name = strenv(ZAPZ_W_VALUE)' "$tmp"
    fi
    if [[ -n "$email" ]]; then
        ZAPZ_W_VALUE="$email" yq -i '.git.user.email = strenv(ZAPZ_W_VALUE)' "$tmp"
    fi
    [[ "$apply_macos" == true ]] || yq -i 'del(.macos)' "$tmp"
    [[ "$updates" == true ]] || yq -i '.cron.update_schedule.enabled = false' "$tmp"

    mkdir -p "$(dirname "$dest")"
    backup_file "$dest"
    mv "$tmp" "$dest"
    printf "\n  ${GREEN}✓${NC} Saved your config to %s\n" "$(tilde_path "$dest")"
}
