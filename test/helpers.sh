#!/usr/bin/env bash

# Shared test helpers. Tests are plain functions; each runs in a subshell
# with `set -e`, so any failing assertion or command fails that test only.
# Keep this file compatible with bash 3.2 (the macOS system bash).

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$TEST_DIR")"
REAL_PATH="$PATH"

TESTS_RUN=0
TESTS_FAILED=0
FAILED_TESTS=()

if [[ -t 1 ]]; then
    _GREEN='\033[0;32m' _RED='\033[0;31m' _BLUE='\033[0;34m' _NC='\033[0m'
else
    _GREEN='' _RED='' _BLUE='' _NC=''
fi

section() {
    printf "\n${_BLUE}== %s ==${_NC}\n" "$1"
}

# Usage: run_test "description" function_name [args...]
run_test() {
    local name="$1"
    shift
    local output status
    output=$(mktemp)

    ( set -e; "$@" ) > "$output" 2>&1
    status=$?

    TESTS_RUN=$((TESTS_RUN + 1))
    if [[ $status -eq 0 ]]; then
        printf "  ${_GREEN}✓${_NC} %s\n" "$name"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILED_TESTS+=("$name")
        printf "  ${_RED}✗ %s${_NC}\n" "$name"
        sed 's/^/      /' "$output"
    fi
    rm -f "$output"
}

# Print a summary and exit non-zero if anything failed
finish_tests() {
    printf '\n%d run, %d failed\n' "$TESTS_RUN" "$TESTS_FAILED"
    if [[ $TESTS_FAILED -gt 0 ]]; then
        local name
        for name in "${FAILED_TESTS[@]}"; do
            printf "  ${_RED}✗ %s${_NC}\n" "$name"
        done
        exit 1
    fi
}

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    return 1
}

assert_eq() {
    [[ "$1" == "$2" ]] || fail "${3:-values differ}: expected [$2], got [$1]"
}

assert_file() {
    [[ -f "$1" ]] || fail "expected file to exist: $1"
}

assert_no_file() {
    [[ ! -e "$1" ]] || fail "expected no file at: $1"
}

# assert_contains <file> <fixed string>
assert_contains() {
    grep -qF -- "$2" "$1" 2>/dev/null || { fail "expected $1 to contain: $2"; cat "$1" 2>/dev/null >&2; return 1; }
}

assert_not_contains() {
    if grep -qF -- "$2" "$1" 2>/dev/null; then
        fail "expected $1 not to contain: $2"
    fi
}

# assert_count <file> <fixed string> <n>
assert_count() {
    local n
    n=$(grep -cF -- "$2" "$1" 2>/dev/null || true)
    assert_eq "${n:-0}" "$3" "occurrences of [$2] in $1"
}

# Create an isolated HOME and a directory of stub commands placed first
# on PATH. Every stub call is recorded in $STUB_LOG as "name args...".
setup_sandbox() {
    SANDBOX=$(mktemp -d)
    export HOME="$SANDBOX/home"
    STUB_BIN="$SANDBOX/bin"
    export STUB_LOG="$SANDBOX/calls.log"
    export STUB_STATE="$SANDBOX/state"
    mkdir -p "$HOME" "$STUB_BIN" "$STUB_STATE"
    : > "$STUB_LOG"
    export PATH="$STUB_BIN:$REAL_PATH"
    export GIT_CONFIG_NOSYSTEM=1
    export SHELL=/bin/zsh
    unset XDG_CONFIG_HOME XDG_CACHE_HOME NVM_DIR ZAPZ_HOME ZAPZ_DISABLE_UPDATE_CHECK
    trap 'rm -rf "$SANDBOX"' EXIT

    local name
    for name in defaults osascript killall sudo launchctl pbcopy ssh-add gh xcode-select sw_vers; do
        stub "$name"
    done
    stub_brew
}

# Create a stub that records its arguments and runs an optional body
# Usage: stub <name> [body]
stub() {
    cat > "$STUB_BIN/$1" << EOF
#!/usr/bin/env bash
echo "$1 \$*" >> "\$STUB_LOG"
${2:-exit 0}
EOF
    chmod +x "$STUB_BIN/$1"
}

# A fake Homebrew. Installed packages are tracked in $STUB_STATE/brew;
# names listed in $STUB_STATE/brew_fail fail to install.
stub_brew() {
    : > "$STUB_STATE/brew"
    : > "$STUB_STATE/brew_fail"
    stub brew '
state="$STUB_STATE/brew"
case "$1" in
    list)
        name="${!#}"
        grep -qx "$name" "$state"
        exit $?
        ;;
    install)
        shift
        [[ "$1" == "--cask" ]] && shift
        if grep -qx "$1" "$STUB_STATE/brew_fail"; then
            echo "Error: $1 failed" >&2
            exit 1
        fi
        echo "$1" >> "$state"
        ;;
    tap)
        [[ $# -eq 1 ]] && grep "^tap:" "$state" | sed "s/^tap://"
        [[ $# -eq 2 ]] && echo "tap:$2" >> "$state"
        exit 0
        ;;
    shellenv) echo "export HOMEBREW_PREFIX=/opt/homebrew" ;;
    --prefix) echo /opt/homebrew ;;
esac
exit 0'
}

# Mark a Homebrew package as already installed
brew_installed() {
    echo "$1" >> "$STUB_STATE/brew"
}

# Source the libraries and all modules into the current (test) shell
load_zapz() {
    VERBOSE=false
    ZAPZ_ROOT="$PROJECT_ROOT"
    # shellcheck source=../lib/version.sh
    source "$PROJECT_ROOT/lib/version.sh"
    # shellcheck source=../lib/logging.sh
    source "$PROJECT_ROOT/lib/logging.sh"
    # shellcheck source=../lib/utils.sh
    source "$PROJECT_ROOT/lib/utils.sh"
    local module
    for module in "$PROJECT_ROOT"/lib/modules/*.sh; do
        # shellcheck source=/dev/null
        source "$module"
    done
}

# Write a config file for the test and point CONFIG_FILE at it
use_config() {
    CONFIG_FILE="$SANDBOX/config.yml"
    cat > "$CONFIG_FILE"
    export CONFIG_FILE
}
