#!/usr/bin/env bash

# The setup wizard. A few short screens (who you are, what you do, extras,
# your picks, terminal and shell) that write config/default.yml from the
# catalog, so nobody has to edit YAML. Used by install.sh and
# `zapz --configure`. Needs open_prompt_input to have been called.

# --- screen helpers --------------------------------------------------------

_screen() {
    printf "\n  ${BOLD}%s${NC}\n" "$1"
    [[ -z "${2:-}" ]] || printf "  ${DIM}%s${NC}\n" "$2"
    printf "\n"
}

# Read space- or comma-separated numbers from 1..max; Enter gives $default.
# "0" or "none" means none. Re-asks until the answer is valid.
# Usage: ask_numbers <prompt> <max> [default]
ask_numbers() {
    local prompt="$1" max="$2" default="${3:-}" answer n valid
    while true; do
        answer=$(ask "$prompt" "$default")
        answer="${answer//,/ }"
        case "$answer" in
            0|none|None|NONE) echo ""; return 0 ;;
        esac
        valid=true
        for n in $answer; do
            if [[ ! "$n" =~ ^[0-9]+$ ]] || ((n < 1 || n > max)); then
                valid=false
            fi
        done
        if [[ "$valid" == true ]]; then
            # de-duplicate, keep order
            # shellcheck disable=SC2086  # split the answer into numbers
            printf '%s\n' $answer | awk '!seen[$0]++' | tr '\n' ' ' | sed 's/ $//'
            echo
            return 0
        fi
        printf "    ${YELLOW}Please use numbers from 1 to %d, like: 1 3${NC}\n" "$max" >&2
    done
}

# Show one "picks" question from a catalog file and select the answers.
# Usage: run_pick <file> <pick index> <heading>
run_pick() {
    local file="$1" p="$2" heading="$3"
    local path=".picks[$p].items" question multi
    question=$(yq e ".picks[$p].question" "$file")
    # Not `.multi // true`: yq's // also replaces false
    if [[ "$(yq e ".picks[$p].multi == false" "$file")" == true ]]; then
        multi=false
    else
        multi=true
    fi

    local kind name label id url run note follow recommended group with
    local i=0 count=0 last_group="-" recommended_numbers=""
    _screen "$heading · $question"
    while IFS=$'\t' read -r kind name label id url run note follow recommended group with; do
        [[ -n "$kind" ]] || continue
        i=$((i + 1))
        if [[ "$group" != "-" && "$group" != "$last_group" ]]; then
            printf "    ${DIM}%s${NC}\n" "$group"
            last_group="$group"
        fi
        local mark="" shown_note=""
        [[ "$note" == "-" ]] || shown_note="$note"
        if [[ "$recommended" == true ]]; then
            mark=" ${GREEN}★${NC}"
            recommended_numbers="${recommended_numbers:+$recommended_numbers }$i"
        fi
        printf "    %2d  %-22s ${DIM}%s${NC}%b\n" "$i" "$label" "$shown_note" "$mark"
    done < <(catalog_items "$file" "$path")
    count=$i

    local numbers
    printf "\n"
    if [[ "$multi" != true ]]; then
        numbers=$(ask_numbers "  Choose one" "$count" "${recommended_numbers%% *}")
        numbers="${numbers%% *}"
    elif [[ -n "$recommended_numbers" ]]; then
        numbers=$(ask_numbers "  Pick any (Enter for ★, 0 for none)" "$count" "$recommended_numbers")
    else
        numbers=$(ask_numbers "  Pick any (Enter to skip)" "$count")
    fi
    # shellcheck disable=SC2086  # word-split the numbers on purpose
    [[ -z "$numbers" ]] || catalog_select_numbers "$file" "$path" $numbers
}

# Run every pick question in a catalog file
run_picks() {
    local file="$1" heading="$2" p count
    count=$(yq e '.picks // [] | length' "$file")
    for ((p = 0; p < count; p++)); do
        run_pick "$file" "$p" "$heading"
    done
}

# A numbered menu of catalog entries; prints the chosen files, one per line
# Usage: choose_entries <personas|packs> <prompt> [default numbers]
choose_entries() {
    local kind="$1" prompt="$2" default="${3:-}"
    local files=() file title tagline i=0 numbers n
    while IFS=$'\t' read -r file title tagline; do
        i=$((i + 1))
        files+=("$file")
        printf "    %2d  %-22s ${DIM}%s${NC}\n" "$i" "$title" "$tagline" >&2
    done < <(catalog_entries "$kind")
    printf "\n" >&2
    numbers=$(ask_numbers "$prompt" "$i" "$default")
    for n in $numbers; do
        printf '%s\n' "${files[n - 1]}"
    done
}

# A single choice between fixed options; prints the chosen value
# Usage: choose_one <prompt> <default number> "value|label|note"...
choose_one() {
    local prompt="$1" default="$2" option value label note i=0 numbers values=()
    shift 2
    for option in "$@"; do
        IFS='|' read -r value label note <<< "$option"
        i=$((i + 1))
        values+=("$value")
        local mark=""
        ((i == default)) && mark=" ${GREEN}★${NC}"
        printf "    %2d  %-22s ${DIM}%s${NC}%b\n" "$i" "$label" "$note" "$mark" >&2
    done
    printf "\n" >&2
    numbers=$(ask_numbers "$prompt" "$i" "$default")
    numbers="${numbers%% *}"
    printf '%s\n' "${values[${numbers:-$default} - 1]}"
}

# --- the wizard ------------------------------------------------------------

# Usage: run_config_wizard <config file to write>
run_config_wizard() {
    local dest="$1" catalog name email file
    catalog="$(catalog_dir)"
    catalog_reset_selection

    printf "\n  ${BOLD}Let's get your Mac ready.${NC}\n\n"
    printf "  Three steps: tell me a little about you (about 3 minutes), review\n"
    printf "  the plan, then let it run (usually 20–45 minutes).\n"
    printf "  ${DIM}Nothing changes until you say go. Enter always picks the ★ recommended choice.${NC}\n"

    _screen "First, who's setting up this Mac?" "Used for your git commits and SSH key."
    name=$(ask "  Your name" "$(git config --global --get user.name 2>/dev/null || id -F 2>/dev/null || true)")
    email=$(ask "  Your email" "$(git config --global --get user.email 2>/dev/null || true)")

    _screen "What will you use this Mac for?" "Pick all that apply. Everyone also gets the essentials: git, a browser, 1Password and modern command-line tools."
    local personas=() packs=()
    while IFS= read -r file; do
        [[ -n "$file" ]] && personas+=("$file")
    done < <(choose_entries personas "  Your picks, e.g. 1 2 6 (Enter for just the essentials)")

    _screen "A few extras people love" "Optional. Pick any, or press Enter to skip."
    while IFS= read -r file; do
        [[ -n "$file" ]] && packs+=("$file")
    done < <(choose_entries packs "  Your picks (Enter to skip)")

    # Everything from the essentials and each choice, plus their questions
    catalog_select_all "$catalog/essentials.yml" .core
    run_picks "$catalog/essentials.yml" "Essentials"
    for file in ${personas[@]+"${personas[@]}"} ${packs[@]+"${packs[@]}"}; do
        catalog_select_all "$file" .core
        run_picks "$file" "$(yq e '.title' "$file")"
    done

    _screen "Which terminal do you want?" "Where you type commands. You can switch any time."
    local terminal shell
    terminal=$(choose_one "  Choose one" 1 \
        "ghostty|Ghostty|fast, native and free; zapz sets the font" \
        "iterm2|iTerm2|the classic, with the most features" \
        "warp|Warp|AI built in; needs an account" \
        "terminal|Keep Terminal|Apple's built-in app")
    case "$terminal" in
        ghostty|iterm2|warp) SEL_CASKS+=("$terminal") ;;
    esac

    _screen "Make your shell friendlier?" "Suggestions as you type, color, and a clear prompt that shows your git branch."
    shell=$(choose_one "  Choose one" 1 \
        "recommended|Recommended|Oh My Zsh, autosuggestions, highlighting, Starship prompt" \
        "light|Light|just the Starship prompt" \
        "none|Leave it alone|no shell changes")
    case "$shell" in
        recommended) SEL_FORMULAS+=(starship zsh-autosuggestions zsh-syntax-highlighting) ;;
        light) SEL_FORMULAS+=(starship) ;;
    esac

    _screen "Last two"
    local apply_macos=true updates=true
    confirm "  Apply recommended macOS settings (Dock, Finder, key repeat, a Screenshots folder)?" Y || apply_macos=false
    confirm "  Keep your apps and tools updated automatically (Mondays at 09:00)?" Y || updates=false

    # Write the config
    local tmp
    tmp=$(mktemp)
    {
        printf '# Created by the zapz setup wizard. Edit freely: every option is\n'
        printf '# described in config/default.yml.example. Re-run with: zapz --configure\n'
        cat "$catalog/base.yml"
    } > "$tmp"

    [[ -z "$name" ]] || ZAPZ_W_VALUE="$name" yq -i '.git.user.name = strenv(ZAPZ_W_VALUE)' "$tmp"
    [[ -z "$email" ]] || ZAPZ_W_VALUE="$email" yq -i '.git.user.email = strenv(ZAPZ_W_VALUE)' "$tmp"
    ZAPZ_W_VALUE="$terminal" yq -i '.terminal.app = strenv(ZAPZ_W_VALUE)' "$tmp"
    ZAPZ_W_VALUE="$shell" yq -i '.shell.setup = strenv(ZAPZ_W_VALUE)' "$tmp"
    [[ "$apply_macos" == true ]] || yq -i 'del(.macos)' "$tmp"
    [[ "$updates" == true ]] || yq -i '.cron.update_schedule.enabled = false' "$tmp"

    local titles
    titles=$(for file in ${personas[@]+"${personas[@]}"} ${packs[@]+"${packs[@]}"}; do yq e '.title' "$file"; done)
    ZAPZ_W_LIST="$titles" yq -i '.profile.chosen = (strenv(ZAPZ_W_LIST) | split("\n") | map(select(. != "")))' "$tmp"

    catalog_write_selection "$tmp"

    # The editor git opens for commit messages: the first editor installed
    local editor=""
    case " ${SEL_CASKS[*]-} " in
        *" visual-studio-code "*) editor="code --wait" ;;
        *" cursor "*) editor="cursor --wait" ;;
        *" zed "*) editor="zed --wait" ;;
    esac
    [[ -z "$editor" ]] || ZAPZ_W_VALUE="$editor" yq -i '.git.editor = strenv(ZAPZ_W_VALUE)' "$tmp"

    mkdir -p "$(dirname "$dest")"
    backup_file "$dest"
    mv "$tmp" "$dest"
    printf "\n  ${GREEN}✓${NC} Saved your setup to %s\n" "$(tilde_path "$dest")"
}
