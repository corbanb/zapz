#!/usr/bin/env bash

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_header() {
    printf "\n${BLUE}=== %s ===${NC}\n" "$1"
}

log_success() {
    printf "${GREEN}✓ %s${NC}\n" "$1"
}

log_info() {
    printf "${BLUE}➜ %s${NC}\n" "$1"
}

log_warning() {
    printf "${YELLOW}! %s${NC}\n" "$1"
}

log_error() {
    printf "${RED}✗ %s${NC}\n" "$1" >&2
}

log_debug() {
    if [[ "$VERBOSE" == true ]]; then
        printf "${YELLOW}DEBUG: %s${NC}\n" "$1"
    fi
} 