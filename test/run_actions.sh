#!/usr/bin/env bash

# Script to run GitHub Actions locally using act or remotely using gh cli
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source utilities for logging
source "${PROJECT_ROOT}/lib/logging.sh"

# Function to check if act is installed
check_act() {
    if ! command -v act &>/dev/null; then
        log_error "act is not installed. Please install it first:"
        echo "  brew install act"
        exit 1
    fi
}

# Function to check if gh cli is installed
check_gh() {
    if ! command -v gh &>/dev/null; then
        log_error "GitHub CLI is not installed. Please install it first:"
        echo "  brew install gh"
        echo "Then authenticate:"
        echo "  gh auth login"
        exit 1
    fi
}

# Function to check if secrets file exists
check_secrets() {
    if [[ ! -f "${PROJECT_ROOT}/.secrets" ]]; then
        log_error ".secrets file not found. Please create it from .secrets.example"
        exit 1
    fi
}

# Function to load secrets
load_secrets() {
    if [[ -f "${PROJECT_ROOT}/.secrets" ]]; then
        # Export all variables from .secrets file
        set -a
        source "${PROJECT_ROOT}/.secrets"
        set +a
    else
        log_error ".secrets file not found"
        exit 1
    fi
}

# Function to run a workflow locally with act
run_workflow_local() {
    local workflow="$1"
    local event="${2:-push}"

    log_info "Running workflow locally: $workflow (Event: $event)"
    act -j "$workflow" \
        --env-file "${PROJECT_ROOT}/.secrets" \
        -s GITHUB_TOKEN \
        -s GITHUB_TOKEN_ALT \
        -e "${PROJECT_ROOT}/test/events/${event}.json" || return 1
}

# Function to run a workflow remotely with gh cli
run_workflow_remote() {
    local workflow="$1"
    local ref="${2:-main}"

    log_info "Running workflow remotely: $workflow (Ref: $ref)"
    gh workflow run "$workflow" --ref "$ref" || return 1

    # Wait for workflow to complete and show status
    log_info "Waiting for workflow to complete..."
    gh run list --workflow="$workflow" --limit 1 --watch
}

# Function to run all workflows
run_all() {
    local mode="$1"
    local failed=0

    case "$mode" in
        "local")
            check_act
            check_secrets
            load_secrets
            ;;
        "remote")
            check_gh
            ;;
        *)
            log_error "Invalid mode: $mode. Use 'local' or 'remote'"
            exit 1
            ;;
    esac

    # Core workflows
    log_header "Running Core Workflows"
    if [[ "$mode" == "local" ]]; then
        run_workflow_local "lint" || ((failed++))
        run_workflow_local "test" || ((failed++))
        run_workflow_local "test-install" || ((failed++))
        run_workflow_local "enforce-pr-rules" "pull_request" || ((failed++))
    else
        gh workflow run lint.yml || ((failed++))
        gh workflow run test.yml || ((failed++))
        gh workflow run install-test.yml || ((failed++))
        gh workflow run pr-checks.yml || ((failed++))
    fi

    # Documentation workflows
    log_header "Running Documentation Workflows"
    if [[ "$mode" == "local" ]]; then
        run_workflow_local "sync-docs" "push" || ((failed++))
        run_workflow_local "build" "push" || ((failed++))
    else
        gh workflow run docs-sync.yml || ((failed++))
        gh workflow run docs-build.yml || ((failed++))
    fi

    # Maintenance workflows
    log_header "Running Maintenance Workflows"
    if [[ "$mode" == "local" ]]; then
        run_workflow_local "update-deps" "workflow_dispatch" || ((failed++))
    else
        gh workflow run dependencies.yml || ((failed++))
    fi

    # Release workflow (only run on demand)
    if [[ "$2" == "--with-release" ]]; then
        log_header "Running Release Workflow"
        if [[ "$mode" == "local" ]]; then
            run_workflow_local "release" "push" || ((failed++))
        else
            gh workflow run release.yml || ((failed++))
        fi
    fi

    # Summary
    echo
    if ((failed > 0)); then
        log_error "$failed workflow(s) failed"
        return 1
    else
        log_success "All workflows completed successfully"
        return 0
    fi
}

# Create events directory if it doesn't exist
mkdir -p "${PROJECT_ROOT}/test/events"

# Create event payload files if they don't exist
if [[ ! -f "${PROJECT_ROOT}/test/events/push.json" ]]; then
    cat > "${PROJECT_ROOT}/test/events/push.json" << 'EOF'
{
  "ref": "refs/heads/main",
  "before": "0000000000000000000000000000000000000000",
  "after": "1111111111111111111111111111111111111111",
  "repository": {
    "name": "macos-developer-setup",
    "full_name": "user/macos-developer-setup",
    "private": false,
    "html_url": "https://github.com/user/macos-developer-setup"
  },
  "pusher": {
    "name": "user",
    "email": "user@example.com"
  }
}
EOF
fi

if [[ ! -f "${PROJECT_ROOT}/test/events/workflow_dispatch.json" ]]; then
    cat > "${PROJECT_ROOT}/test/events/workflow_dispatch.json" << 'EOF'
{
  "inputs": {},
  "ref": "refs/heads/main",
  "repository": {
    "name": "macos-developer-setup",
    "full_name": "user/macos-developer-setup",
    "private": false,
    "html_url": "https://github.com/user/macos-developer-setup"
  }
}
EOF
fi

validate_pr() {
    local TITLE="$1"
    local RESULTS=""
    local HAS_ERRORS=0

    echo "Checking PR title: $TITLE"

    # Check format
    if ! echo "$TITLE" | grep -E "^(feat|fix|docs|style|refactor|test|chore)\([a-z-]+\): .+$" > /dev/null; then
        RESULTS+="❌ PR title must follow format: type(scope): description\n"
        RESULTS+="Valid types: feat, fix, docs, style, refactor, test, chore\n"
        RESULTS+="Example: feat(core): add new feature\n"
        HAS_ERRORS=1
    else
        RESULTS+="✅ PR title format is valid\n"
    fi

    # Check length
    if [ ${#TITLE} -gt 72 ]; then
        RESULTS+="❌ PR title must be 72 characters or less (current: ${#TITLE})\n"
        HAS_ERRORS=1
    fi

    # Run other checks and collect their results
    if ! ./test/test.sh; then
        RESULTS+="❌ Tests failed\n"
        HAS_ERRORS=1
    else
        RESULTS+="✅ Tests passed\n"
    fi

    if ! ./test/run_actions.sh local lint; then
        RESULTS+="❌ Linting failed\n"
        HAS_ERRORS=1
    else
        RESULTS+="✅ Linting passed\n"
    fi

    # Output all results at once
    echo -e "$RESULTS"

    if [ $HAS_ERRORS -eq 1 ]; then
        echo "::set-output name=pr_comment::$RESULTS"
        return 1
    else
        echo "::set-output name=pr_comment::✅ All PR requirements met!\n$RESULTS"
        return 0
    fi
}

# Main function
main() {
    case "$1" in
        "local")
            shift
            run_local_command "$@"
            ;;
        "remote")
            shift
            run_remote_command "$@"
            ;;
        "validate-pr")
            validate_pr "$2"
            exit $?
            ;;
        *)
            echo "Usage: $0 <mode> <command>"
            echo "Modes:"
            echo "  local     - Run workflows locally using act"
            echo "  remote    - Run workflows remotely using GitHub"
            echo
            echo "Commands:"
            echo "  lint      - Run linting workflow"
            echo "  test      - Run test workflow"
            echo "  install   - Run installation test workflow"
            echo "  docs      - Run documentation workflows"
            echo "  deps      - Run dependency update workflow"
            echo "  release   - Run release workflow"
            echo "  all       - Run all workflows"
            echo
            echo "Options:"
            echo "  --with-release  - Include release workflow when running all"
            echo
            echo "Examples:"
            echo "  $0 local lint              # Run lint workflow locally"
            echo "  $0 remote test             # Run test workflow on GitHub"
            echo "  $0 local all               # Run all workflows locally"
            echo "  $0 remote all --with-release # Run all workflows on GitHub"
            exit 1
            ;;
    esac
}

# Run local workflow command
run_local_command() {
    check_act
    check_secrets
    load_secrets

    case "$1" in
        "lint")
            run_workflow_local "lint"
            ;;
        "test")
            run_workflow_local "test"
            ;;
        "install")
            run_workflow_local "test-install"
            ;;
        "docs")
            run_workflow_local "sync-docs" "push" && \
            run_workflow_local "build" "push"
            ;;
        "deps")
            run_workflow_local "update-deps" "workflow_dispatch"
            ;;
        "release")
            run_workflow_local "release" "push"
            ;;
        "all")
            run_all "local" "${@:2}"
            ;;
        *)
            echo "Invalid command: $1"
            exit 1
            ;;
    esac
}

# Run remote workflow command
run_remote_command() {
    check_gh

    case "$1" in
        "lint")
            gh workflow run lint.yml
            ;;
        "test")
            gh workflow run test.yml
            ;;
        "install")
            gh workflow run install-test.yml
            ;;
        "docs")
            gh workflow run docs-sync.yml && \
            gh workflow run docs-build.yml
            ;;
        "deps")
            gh workflow run dependencies.yml
            ;;
        "release")
            gh workflow run release.yml
            ;;
        "all")
            run_all "remote" "${@:2}"
            ;;
        *)
            echo "Invalid command: $1"
            exit 1
            ;;
    esac
}

# Run script
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
