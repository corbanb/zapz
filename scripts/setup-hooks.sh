#!/usr/bin/env bash

# Script to set up git hooks
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source utilities for logging
source "${PROJECT_ROOT}/lib/logging.sh"

# Create hooks directory if it doesn't exist
mkdir -p "${PROJECT_ROOT}/.git/hooks"

# Create pre-commit hook
cat > "${PROJECT_ROOT}/.git/hooks/pre-commit" << 'EOF'
#!/usr/bin/env bash

# Get the project root directory
PROJECT_ROOT="$(git rev-parse --show-toplevel)"

# Source logging utilities
source "${PROJECT_ROOT}/lib/logging.sh"

log_header "Running pre-commit checks..."

# Run linting
log_info "Running linting checks..."
"${PROJECT_ROOT}/test/run_actions.sh" local lint || {
    log_error "Linting failed. Please fix errors before committing."
    exit 1
}

# Run core tests
log_info "Running core tests..."
"${PROJECT_ROOT}/test/test.sh" || {
    log_error "Tests failed. Please fix errors before committing."
    exit 1
}

log_success "All pre-commit checks passed!"
EOF

# Make the hook executable
chmod +x "${PROJECT_ROOT}/.git/hooks/pre-commit"

# Create pre-push hook
cat > "${PROJECT_ROOT}/.git/hooks/pre-push" << 'EOF'
#!/usr/bin/env bash

# Get the project root directory
PROJECT_ROOT="$(git rev-parse --show-toplevel)"

# Source logging utilities
source "${PROJECT_ROOT}/lib/logging.sh"

log_header "Running pre-push checks..."

# Run full test suite
log_info "Running full test suite..."
"${PROJECT_ROOT}/test/run_tests.sh" || {
    log_error "Test suite failed. Please fix errors before pushing."
    exit 1
}

# Run all workflows locally
log_info "Running all workflows locally..."
"${PROJECT_ROOT}/test/run_actions.sh" local all || {
    log_error "Workflow tests failed. Please fix errors before pushing."
    exit 1
}

log_success "All pre-push checks passed!"
EOF

# Make the hook executable
chmod +x "${PROJECT_ROOT}/.git/hooks/pre-push"

log_success "Git hooks installed successfully!"
EOF
