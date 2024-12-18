#!/usr/bin/env bash

# Script to run YAML linting on all YAML files
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source utilities for logging
source "${PROJECT_ROOT}/lib/logging.sh"

# Check for yamllint
if ! command -v yamllint &> /dev/null; then
    log_error "yamllint is not installed. Installing..."
    brew install yamllint
fi

# Find all YAML files
log_info "Finding YAML files..."
yaml_files=$(find "${PROJECT_ROOT}" \
    -type f \
    \( -name "*.yml" -o -name "*.yaml" \) \
    ! -path "*/node_modules/*" \
    ! -path "*/.git/*")

# Count files
file_count=$(echo "$yaml_files" | wc -l | tr -d ' ')
log_info "Found $file_count YAML files to check"

# Run yamllint
log_header "Running YAML lint"
echo "$yaml_files" | while read -r file; do
    if [[ -f "$file" ]]; then
        log_info "Checking: $(basename "$file")"
        if ! yamllint -c "${PROJECT_ROOT}/.yamllint" "$file"; then
            log_error "Errors found in: $file"
        fi
    fi
done

log_success "YAML lint check complete"
