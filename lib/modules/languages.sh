#!/usr/bin/env bash

# Programming languages and runtimes through mise (https://mise.jdx.dev):
# one tool for Node.js, Python, Bun, Go, Rust and more, with per-project
# versions. Tools come from languages.tools, e.g. node@lts, python@3.13.

setup_languages() {
    log_header "Languages"

    if [[ -z "$(config_list '.languages.tools')" ]]; then
        ui_item skipped "Languages" "none in your config"
        return 0
    fi
    if ! command_exists mise; then
        ui_item failed "mise" "not installed (add \"mise\" to homebrew.formulas)"
        return 0
    fi

    # Use mise's tools in new shells
    local shell_name=zsh
    [[ "${SHELL:-}" == */bash ]] && shell_name=bash
    write_managed_block "$(shell_rc_file)" "mise" "eval \"\$(mise activate $shell_name)\""

    local tool
    while IFS= read -r tool; do
        [[ -n "$tool" ]] || continue
        if mise where "$tool" >/dev/null 2>&1; then
            ui_item existing "$tool" "already installed"
        else
            run_quiet "$tool" mise use --global --yes "$tool" || true
        fi
    done < <(config_list '.languages.tools')
}
