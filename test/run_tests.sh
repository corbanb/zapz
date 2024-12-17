#!/usr/bin/env bash

# Main test runner script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test files to run
declare -a TEST_FILES=(
    "test.sh"
    "test_install.sh"
)

# Run all test files
run_all_tests() {
    local failed=0
    
    echo -e "${BLUE}=== Running All Tests ===${NC}"
    echo
    
    for test_file in "${TEST_FILES[@]}"; do
        echo -e "${BLUE}Running ${test_file}...${NC}"
        if bash "${SCRIPT_DIR}/${test_file}"; then
            echo -e "${GREEN}✓ ${test_file} passed${NC}"
        else
            echo -e "${RED}✗ ${test_file} failed${NC}"
            failed=1
        fi
        echo
    done
    
    if ((failed)); then
        echo -e "${RED}=== Some tests failed ===${NC}"
        exit 1
    else
        echo -e "${GREEN}=== All test suites passed ===${NC}"
    fi
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_all_tests
fi 