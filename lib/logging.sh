#!/usr/bin/env bash

# Output for zapz: step headers, one tidy line per item, quiet commands with
# a spinner (full output goes to a log file), and a closing summary.
# Colors and the spinner are only used on a terminal; NO_COLOR turns colors
# off (https://no-color.org).

if [[ -t 1 && -z "${NO_COLOR:-}" && "${TERM:-}" != dumb ]]; then
    RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[0;33m'
    BLUE='\033[0;34m' BOLD='\033[1m' DIM='\033[2m' NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' BOLD='' DIM='' NC=''
fi

# Results collected for the summary
ZAPZ_COUNT_CHANGED=0
ZAPZ_COUNT_EXISTING=0
ZAPZ_FAILED=()
ZAPZ_NEXT_STEPS=()
ZAPZ_STEP=0
ZAPZ_STEP_TOTAL="${ZAPZ_STEP_TOTAL:-0}"

# Append plain text to the run log, if there is one
_log_to_file() {
    [[ -n "${ZAPZ_LOG:-}" ]] || return 0
    printf '%s\n' "$*" >> "$ZAPZ_LOG" 2>/dev/null || true
}

# Start (or reuse) the log file for this run
ensure_log_file() {
    if [[ -z "${ZAPZ_LOG:-}" ]]; then
        local dir="$HOME/Library/Logs/zapz"
        mkdir -p "$dir" 2>/dev/null || dir="${TMPDIR:-/tmp}"
        ZAPZ_LOG="$dir/setup-${ZAPZ_RUN_ID:-$(date +%Y%m%d-%H%M%S)}.log"
    fi
    : >> "$ZAPZ_LOG"
    export ZAPZ_LOG
}

# A numbered section: "[3/7] Git" (just the title without a step count)
log_header() {
    ZAPZ_STEP=$((ZAPZ_STEP + 1))
    if ((ZAPZ_STEP_TOTAL > 0)); then
        printf "\n${BOLD}${BLUE}[%d/%d]${NC} ${BOLD}%s${NC}\n" "$ZAPZ_STEP" "$ZAPZ_STEP_TOTAL" "$1"
    else
        printf "\n${BOLD}%s${NC}\n" "$1"
    fi
    _log_to_file "" "== $1"
}

log_success() {
    printf "  ${GREEN}✓${NC} %s\n" "$1"
    _log_to_file "ok: $1"
}

log_info() {
    printf "  ${BLUE}➜${NC} %s\n" "$1"
    _log_to_file "info: $1"
}

log_warning() {
    printf "  ${YELLOW}!${NC} %s\n" "$1"
    _log_to_file "warning: $1"
}

log_error() {
    printf "  ${RED}✗ %s${NC}\n" "$1" >&2
    _log_to_file "error: $1"
}

log_debug() {
    if [[ "${VERBOSE:-false}" == true ]]; then
        printf "${DIM}  %s${NC}\n" "$1"
    fi
    _log_to_file "debug: $1"
}

# One result line, counted for the summary.
# Usage: ui_item <changed|housekeeping|existing|skipped|failed> <label> [detail]
ui_item() {
    local state="$1" label="$2" detail="${3:-}"
    case "$state" in
        changed)
            ZAPZ_COUNT_CHANGED=$((ZAPZ_COUNT_CHANGED + 1))
            printf "  ${GREEN}✓${NC} %-28s ${DIM}%s${NC}\n" "$label" "$detail" ;;
        housekeeping)
            # Housekeeping that doesn't change your setup (not counted)
            printf "  ${GREEN}✓${NC} %-28s ${DIM}%s${NC}\n" "$label" "$detail" ;;
        existing)
            ZAPZ_COUNT_EXISTING=$((ZAPZ_COUNT_EXISTING + 1))
            printf "  ${DIM}· %-28s %s${NC}\n" "$label" "${detail:-already set}" ;;
        skipped)
            printf "  ${YELLOW}-${NC} %-28s ${DIM}%s${NC}\n" "$label" "$detail" ;;
        failed)
            ZAPZ_FAILED+=("$label${detail:+ ($detail)}")
            printf "  ${RED}✗${NC} %-28s ${RED}%s${NC}\n" "$label" "${detail:-failed}" ;;
    esac
    _log_to_file "$state: $label${detail:+ ($detail)}"
}

# Something to tell the user at the end
add_next_step() {
    ZAPZ_NEXT_STEPS+=("$1")
}

# Something only the user can do, with an optional link to open or command
# to run. Shown as a numbered checklist at the end.
# Usage: add_checklist <title> [url] [command]
ZAPZ_CHECKLIST=()
add_checklist() {
    local entry
    for entry in ${ZAPZ_CHECKLIST[@]+"${ZAPZ_CHECKLIST[@]}"}; do
        [[ "${entry%%|*}" != "$1" ]] || return 0
    done
    ZAPZ_CHECKLIST+=("$1|${2:-}|${3:-}")
}

# The checklist, then an offer to open its links
ui_checklist() {
    ((${#ZAPZ_CHECKLIST[@]} > 0)) || return 0
    local entry title url cmd i=0 links=0
    printf "\n  ${BOLD}Things only you can do${NC}\n"
    for entry in "${ZAPZ_CHECKLIST[@]}"; do
        IFS='|' read -r title url cmd <<< "$entry"
        i=$((i + 1))
        printf "  %2d  %s\n" "$i" "$title"
        [[ -z "$cmd" ]] || printf "      ${DIM}run:${NC} %s\n" "$cmd"
        [[ -z "$url" ]] || links=$((links + 1))
    done
    if ((links > 0)) && [[ -n "${ZAPZ_PROMPT_FD:-}" ]] && command -v open >/dev/null 2>&1; then
        printf "\n"
        if confirm "  Open the $links link(s) now?" Y; then
            for entry in "${ZAPZ_CHECKLIST[@]}"; do
                IFS='|' read -r title url cmd <<< "$entry"
                [[ -z "$url" ]] || open "$url" >/dev/null 2>&1 || true
            done
        fi
    fi
}

# Show a path under $HOME as ~/...
tilde_path() {
    # shellcheck disable=SC2088  # a literal ~ is the point
    case "$1" in
        "$HOME"/*) printf '~/%s' "${1#"$HOME"/}" ;;
        *) printf '%s' "$1" ;;
    esac
}

_format_duration() {
    local s="$1"
    if ((s >= 60)); then
        printf '%dm %02ds' $((s / 60)) $((s % 60))
    else
        printf '%ds' "$s"
    fi
}

# Spinner shown while a command runs; started in the background and killed
# when the command finishes
_spinner() {
    local label="$1" start="$2" i=0
    # An array, not a string: bash 3.2 may slice multi-byte text by bytes
    local frames=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
    while true; do
        printf "\r  ${BLUE}%s${NC} %-28s ${DIM}%s${NC}" \
            "${frames[i % 10]}" "$label" "$(_format_duration $((SECONDS - start)))"
        i=$((i + 1))
        sleep 0.1
    done
}

_stop_spinner() {
    [[ -n "${ZAPZ_SPINNER_PID:-}" ]] || return 0
    kill "$ZAPZ_SPINNER_PID" 2>/dev/null || true
    wait "$ZAPZ_SPINNER_PID" 2>/dev/null || true
    ZAPZ_SPINNER_PID=""
    printf '\r\033[K'
}

# Run a noisy command quietly: show a spinner (on a terminal) and then a
# single result line; send its output to the log, and show the end of it
# only if it fails. Returns the command's exit status.
#
# The command runs in the foreground, so Ctrl-C stops it (not just zapz)
# and shell functions such as nvm keep their effects in this shell.
# Usage: run_quiet [--housekeeping] [--soft <reason>] <label> <command> [args...]
# --housekeeping: success isn't counted as a change in the summary
# --soft <reason>: a failure is expected and fixable by the user, so it's
#   shown as skipped with that reason instead of as a problem
run_quiet() {
    local success_state=changed soft_reason=""
    while [[ "$1" == --* ]]; do
        case "$1" in
            --housekeeping) success_state=housekeeping; shift ;;
            --soft) soft_reason="$2"; shift 2 ;;
            *) break ;;
        esac
    done
    local label="$1"
    shift
    local start=$SECONDS status=0
    ensure_log_file
    printf '\n$ %s\n' "$*" >> "$ZAPZ_LOG"
    # Remember where this command's output starts, to show only it on failure
    local first_line
    first_line=$(($(wc -l < "$ZAPZ_LOG") + 1))

    if [[ -t 1 ]]; then
        _spinner "$label" "$start" &
        ZAPZ_SPINNER_PID=$!
        trap '_stop_spinner; printf "  Stopped.\n"; exit 130' INT TERM
    fi
    "$@" < /dev/null >> "$ZAPZ_LOG" 2>&1 || status=$?
    if [[ -t 1 ]]; then
        trap - INT TERM
        _stop_spinner
    fi

    if ((status == 0)); then
        ui_item "$success_state" "$label" "$(_format_duration $((SECONDS - start)))"
    elif [[ -n "$soft_reason" ]]; then
        ui_item skipped "$label" "$soft_reason"
    else
        ui_item failed "$label" "exit $status"
        # Last lines of this command's output, minus progress-bar noise
        tail -n "+$first_line" "$ZAPZ_LOG" | tr '\r' '\n' | grep -v '^[#[:space:]]*[0-9.]*%\?$' \
            | grep -v "^failed: $label" | tail -n 10 | sed "s/^/      /" >&2
    fi
    return "$status"
}

# Banner-free closing summary with counts, problems and next steps
ui_summary() {
    local elapsed="$1" item
    printf '\n%s\n' "────────────────────────────────────────────────"
    if ((${#ZAPZ_FAILED[@]} == 0)); then
        printf "${GREEN}${BOLD}✓ Your Mac is ready ⚡${NC}  ${DIM}%s${NC}\n" "$(_format_duration "$elapsed")"
    else
        printf "${YELLOW}${BOLD}! Finished with %d problem(s)${NC} in %s\n" \
            "${#ZAPZ_FAILED[@]}" "$(_format_duration "$elapsed")"
    fi
    printf "  %d changed · %d already set\n" "$ZAPZ_COUNT_CHANGED" "$ZAPZ_COUNT_EXISTING"
    if ((${#ZAPZ_FAILED[@]} > 0)); then
        printf "\n  ${BOLD}Problems${NC}\n"
        for item in "${ZAPZ_FAILED[@]}"; do
            printf "  ${RED}✗${NC} %s\n" "$item"
        done
    fi
    ui_checklist
    if ((${#ZAPZ_NEXT_STEPS[@]} > 0)); then
        printf "\n  ${BOLD}Next${NC}\n"
        for item in "${ZAPZ_NEXT_STEPS[@]}"; do
            printf "  ➜ %s\n" "$item"
        done
    fi
    [[ -z "${ZAPZ_LOG:-}" ]] || printf "\n  ${DIM}Full log: %s${NC}\n" "$(tilde_path "$ZAPZ_LOG")"
    if [[ -n "${ZAPZ_BACKUP_DIR:-}" && -d "$ZAPZ_BACKUP_DIR" ]]; then
        printf "  ${DIM}Backups of edited files: %s${NC}\n" "$(tilde_path "$ZAPZ_BACKUP_DIR")"
    fi
}

# macOS notification, for long runs the user may have walked away from
notify() {
    command -v osascript >/dev/null 2>&1 || return 0
    osascript -e "display notification \"$1\" with title \"zapz\" sound name \"Glass\"" >/dev/null 2>&1 || true
}
