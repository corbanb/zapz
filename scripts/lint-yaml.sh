#!/usr/bin/env bash

# Lint the project's YAML files; exits non-zero on any error
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# shellcheck source=../lib/logging.sh
source "${PROJECT_ROOT}/lib/logging.sh"

if ! command -v yamllint &> /dev/null; then
    log_error "yamllint is not installed (brew install yamllint)"
    exit 1
fi

cd "$PROJECT_ROOT" || exit 1
if yamllint -c .yamllint .github config/default.yml.example .yamllint; then
    log_success "YAML lint passed"
else
    log_error "YAML lint found problems"
    exit 1
fi
