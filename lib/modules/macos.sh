#!/usr/bin/env bash

# Every macOS setting zapz manages: type|config path|domain|key|label.
# The plan preview reads this table too, so it always matches what's applied.
ZAPZ_MACOS_SETTINGS=(
    "bool|.macos.dock.autohide|com.apple.dock|autohide|Dock: auto-hide"
    "bool|.macos.dock.magnification|com.apple.dock|magnification|Dock: magnification"
    "bool|.macos.dock.minimize-to-application|com.apple.dock|minimize-to-application|Dock: minimize into app"
    "int|.macos.keyboard.key_repeat|NSGlobalDomain|KeyRepeat|Key repeat rate"
    "int|.macos.keyboard.initial_key_repeat|NSGlobalDomain|InitialKeyRepeat|Key repeat delay"
    "bool|.macos.finder.show_all_extensions|NSGlobalDomain|AppleShowAllExtensions|Finder: file extensions"
    "bool|.macos.finder.show_hidden_files|com.apple.finder|AppleShowAllFiles|Finder: hidden files"
    "bool|.macos.finder.show_path_bar|com.apple.finder|ShowPathbar|Finder: path bar"
    "bool|.macos.finder.show_status_bar|com.apple.finder|ShowStatusBar|Finder: status bar"
)

# Print "label|value" for each setting the config sets (valid values only)
configured_macos_settings() {
    local entry type path rest label value
    for entry in "${ZAPZ_MACOS_SETTINGS[@]}"; do
        IFS='|' read -r type path rest <<< "$entry"
        label="${entry##*|}"
        value=$(config_get "$path")
        [[ -n "$value" ]] || continue
        case "$type" in
            bool)
                [[ "$value" == true || "$value" == false ]] || continue
                if [[ "$value" == true ]]; then value=on; else value=off; fi
                ;;
            int)
                [[ "$value" =~ ^[0-9]+$ ]] || continue
                ;;
        esac
        printf '%s|%s\n' "$label" "$value"
    done
}

# Apply one setting, skipping it when macOS already has that value
apply_macos_setting() {
    local type="$1" path="$2" domain="$3" key="$4" label="$5"
    local value current wanted shown
    value=$(config_get "$path")
    [[ -n "$value" ]] || return 0

    case "$type" in
        bool)
            if [[ "$value" != true && "$value" != false ]]; then
                ui_item skipped "$label" "expected true or false in $path"
                return 0
            fi
            if [[ "$value" == true ]]; then wanted=1 shown=on; else wanted=0 shown=off; fi
            ;;
        int)
            if [[ ! "$value" =~ ^[0-9]+$ ]]; then
                ui_item skipped "$label" "expected a number in $path"
                return 0
            fi
            wanted="$value" shown="$value"
            ;;
    esac

    current=$(defaults read "$domain" "$key" 2>/dev/null || true)
    if [[ "$current" == "$wanted" ]]; then
        ui_item existing "$label" "$shown"
    else
        defaults write "$domain" "$key" "-$type" "$value"
        ui_item changed "$label" "$shown"
        ZAPZ_MACOS_CHANGED=true
    fi
}

setup_macos_preferences() {
    log_header "macOS settings"
    ZAPZ_MACOS_CHANGED=false

    if [[ -z "$(configured_macos_settings)" ]] && ! config_enabled '.macos.developer_mode'; then
        ui_item skipped "macOS settings" "none in your config"
        return 0
    fi

    # Close the settings app so it doesn't overwrite our changes
    # (renamed from System Preferences in macOS 13)
    osascript -e 'tell application "System Settings" to quit' &>/dev/null || true
    osascript -e 'tell application "System Preferences" to quit' &>/dev/null || true

    local entry type path domain key label
    for entry in "${ZAPZ_MACOS_SETTINGS[@]}"; do
        IFS='|' read -r type path domain key label <<< "$entry"
        apply_macos_setting "$type" "$path" "$domain" "$key" "$label"
    done

    # Lets debuggers attach without a password prompt each time; needs admin
    if config_enabled '.macos.developer_mode'; then
        if DevToolsSecurity -status 2>/dev/null | grep -q enabled; then
            ui_item existing "Developer Mode" "on"
        elif sudo /usr/sbin/DevToolsSecurity -enable >/dev/null 2>&1; then
            ui_item changed "Developer Mode" "on"
        else
            ui_item failed "Developer Mode" "couldn't enable"
        fi
    fi

    # Restart Dock/Finder only if something changed, so re-runs don't flicker
    if [[ "$ZAPZ_MACOS_CHANGED" == true ]]; then
        local app
        for app in "Dock" "Finder" "SystemUIServer"; do
            killall "$app" &>/dev/null || true
        done
    fi
}
