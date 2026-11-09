#!/usr/bin/env bash

# Mac App Store apps (apps.app_store) through mas. App Store installs need
# you signed in to the App Store and, for paid apps, to have bought the app;
# anything that can't install becomes a checklist item that opens its page.

setup_app_store() {
    log_header "App Store"

    local count
    count=$(yq e '.apps.app_store // [] | length' "$CONFIG_FILE")
    if ((count == 0)); then
        ui_item skipped "App Store" "no apps in your config"
        return 0
    fi
    if ! command_exists mas; then
        ui_item failed "App Store" "mas isn't installed (add \"mas\" to homebrew.formulas)"
        return 0
    fi

    local installed name id
    installed=$(mas list 2>/dev/null | awk '{print $1}' || true)
    while IFS=$'\t' read -r name id; do
        [[ -n "$id" ]] || continue
        if grep -qx "$id" <<< "$installed"; then
            ui_item existing "$name" "already installed"
        elif ! run_quiet --soft "sign in to the App Store or buy it first" "$name" mas install "$id"; then
            add_checklist "Get $name from the App Store (sign in or buy it first)" \
                "macappstore://apps.apple.com/app/id$id"
        fi
    done < <(yq e '.apps.app_store[] | [.name, (.id | tostring)] | @tsv' "$CONFIG_FILE")
}
