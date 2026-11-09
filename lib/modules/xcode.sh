#!/usr/bin/env bash

# Wait for the Command Line Tools installer started by `xcode-select --install`
wait_for_command_line_tools() {
    local waited=0 timeout="${ZAPZ_XCODE_TIMEOUT:-1800}"
    until xcode-select -p &>/dev/null; do
        if ((waited >= timeout)); then
            return 1
        fi
        sleep 5
        waited=$((waited + 5))
    done
}

install_xcode_tools() {
    log_header "Command Line Tools"

    if xcode-select -p &>/dev/null; then
        ui_item existing "Command Line Tools" "already installed"
        return 0
    fi

    # Opens Apple's installer dialog; exits non-zero if one is already open
    xcode-select --install &>/dev/null || true
    printf "  Click Install in the dialog that opened. This can take several minutes.\n"
    if ! run_quiet "Command Line Tools" wait_for_command_line_tools; then
        log_error "The Command Line Tools still aren't installed"
        log_info "Run 'xcode-select --install', finish the installer, then run zapz again"
        exit 1
    fi
}
