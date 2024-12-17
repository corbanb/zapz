#!/usr/bin/env bash

# Script to run GitHub Actions locally using act
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

# Function to run a specific workflow
run_workflow() {
    local workflow="$1"
    local event="${2:-push}"

    log_info "Running workflow: $workflow (Event: $event)"
    act -j "$workflow" \
        --env-file "${PROJECT_ROOT}/.secrets" \
        -s GITHUB_TOKEN \
        -s GITHUB_TOKEN_ALT \
        -e "${PROJECT_ROOT}/test/events/${event}.json" || return 1
}

# Function to run all workflows
run_all() {
    local failed=0

    # Core workflows
    log_header "Running Core Workflows"
    run_workflow "lint" || ((failed++))
    run_workflow "test" || ((failed++))
    run_workflow "test-install" || ((failed++))
    run_workflow "enforce-pr-rules" "pull_request" || ((failed++))

    # Documentation workflows
    log_header "Running Documentation Workflows"
    run_workflow "sync-docs" "push" || ((failed++))
    run_workflow "build" "push" || ((failed++))

    # Maintenance workflows
    log_header "Running Maintenance Workflows"
    run_workflow "update-deps" "workflow_dispatch" || ((failed++))

    # Release workflow (only run on demand)
    if [[ "$1" == "--with-release" ]]; then
        log_header "Running Release Workflow"
        run_workflow "release" "push" || ((failed++))
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

# Main function
main() {
    check_act
    check_secrets
    load_secrets

    case "$1" in
        "lint")
            run_workflow "lint"
            ;;
        "test")
            run_workflow "test"
            ;;
        "install")
            run_workflow "test-install"
            ;;
        "docs")
            run_workflow "sync-docs" "push" && \
            run_workflow "build" "push"
            ;;
        "deps")
            run_workflow "update-deps" "workflow_dispatch"
            ;;
        "release")
            run_workflow "release" "push"
            ;;
        "all")
            run_all "${@:2}"
            ;;
        *)
            echo "Usage: $0 <command>"
            echo "Commands:"
            echo "  lint      - Run linting workflow"
            echo "  test      - Run test workflow"
            echo "  install   - Run installation test workflow"
            echo "  docs      - Run documentation workflows"
            echo "  deps      - Run dependency update workflow"
            echo "  release   - Run release workflow"
            echo "  all       - Run all workflows"
            echo "Options:"
            echo "  --with-release  - Include release workflow when running all"
            exit 1
            ;;
    esac
}

# Run script
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
