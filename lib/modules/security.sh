#!/usr/bin/env bash

# Safer defaults: Touch ID for sudo, the firewall on, and a FileVault check.
# Each runs only when the config turns it on (the setup wizard does), so a
# config without a security section never changes these settings.
# zapz never turns FileVault on itself (it shows a recovery key you must
# save), so it adds a checklist item instead.

ZAPZ_PAM_SUDO_LOCAL="${ZAPZ_PAM_SUDO_LOCAL:-/etc/pam.d/sudo_local}"
ZAPZ_SOCKETFILTERFW="${ZAPZ_SOCKETFILTERFW:-/usr/libexec/ApplicationFirewall/socketfilterfw}"

touch_id_sudo_enabled() {
    grep -qE '^[[:space:]]*auth[[:space:]]+sufficient[[:space:]]+pam_tid\.so' "$ZAPZ_PAM_SUDO_LOCAL" 2>/dev/null
}

firewall_enabled() {
    "$ZAPZ_SOCKETFILTERFW" --getglobalstate 2>/dev/null | grep -q enabled
}

filevault_on() {
    fdesetup status 2>/dev/null | grep -q "FileVault is On"
}

# Succeeds if a security setting needs the password to change
security_needs_admin() {
    { config_enabled '.security.touch_id_sudo' && ! touch_id_sudo_enabled; } \
        || { config_enabled '.security.firewall' && ! firewall_enabled; }
}

setup_security() {
    log_header "Security"

    if config_enabled '.security.touch_id_sudo'; then
        if touch_id_sudo_enabled; then
            ui_item existing "Touch ID for sudo" "on"
        # sudo_local survives macOS updates (unlike editing pam.d/sudo)
        elif printf 'auth       sufficient     pam_tid.so\n' | sudo tee -a "$ZAPZ_PAM_SUDO_LOCAL" >/dev/null; then
            ui_item changed "Touch ID for sudo" "on"
        else
            ui_item failed "Touch ID for sudo" "couldn't turn on"
        fi
    fi

    if config_enabled '.security.firewall'; then
        if firewall_enabled; then
            ui_item existing "Firewall" "on"
        elif sudo "$ZAPZ_SOCKETFILTERFW" --setglobalstate on >/dev/null 2>&1; then
            ui_item changed "Firewall" "on"
        else
            ui_item failed "Firewall" "couldn't turn on"
        fi
    fi

    if config_enabled '.security.filevault_check'; then
        if filevault_on; then
            ui_item existing "FileVault" "on"
        else
            ui_item skipped "FileVault" "off; added to your checklist"
            add_checklist "Turn on FileVault (and save the recovery key somewhere safe)" \
                "x-apple.systempreferences:com.apple.preference.security?FileVault"
        fi
    fi
}
