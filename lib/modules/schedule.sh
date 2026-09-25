#!/usr/bin/env bash

# Schedules lib/maintenance.sh with a launchd LaunchAgent. launchd is the
# supported scheduler on macOS; unlike cron it runs missed jobs after sleep.

ZAPZ_LAUNCH_AGENT_LABEL="com.github.corbanb.zapz.update"

launch_agent_path() {
    printf '%s\n' "$HOME/Library/LaunchAgents/${ZAPZ_LAUNCH_AGENT_LABEL}.plist"
}

# Print the launchd weekday number (0 = Sunday) for a day name
get_day_number() {
    case "$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')" in
        sunday) echo 0 ;;
        monday) echo 1 ;;
        tuesday) echo 2 ;;
        wednesday) echo 3 ;;
        thursday) echo 4 ;;
        friday) echo 5 ;;
        saturday) echo 6 ;;
        *) return 1 ;;
    esac
}

# Print the StartCalendarInterval entries for the configured schedule
calendar_intervals() {
    local frequency="$1" hour="$2" minute="$3"
    local base="<key>Hour</key><integer>${hour}</integer><key>Minute</key><integer>${minute}</integer>"

    case "$frequency" in
        daily)
            printf '        <dict>%s</dict>\n' "$base"
            ;;
        weekly)
            local day number found=false
            while IFS= read -r day; do
                [[ -n "$day" ]] || continue
                if ! number=$(get_day_number "$day"); then
                    log_error "Invalid day in cron.update_schedule.days: $day"
                    return 1
                fi
                printf '        <dict><key>Weekday</key><integer>%s</integer>%s</dict>\n' "$number" "$base"
                found=true
            done < <(config_list '.cron.update_schedule.days')
            if [[ "$found" != true ]]; then
                log_error "Weekly updates need at least one day in cron.update_schedule.days"
                return 1
            fi
            ;;
        monthly)
            printf '        <dict><key>Day</key><integer>1</integer>%s</dict>\n' "$base"
            ;;
        *)
            log_error "Invalid update frequency: $frequency (use daily, weekly or monthly)"
            return 1
            ;;
    esac
}

unload_launch_agent() {
    local plist="$1"
    launchctl bootout "gui/$(id -u)" "$plist" >/dev/null 2>&1 || true
}

setup_scheduled_updates() {
    log_header "Setting up scheduled updates"

    local plist
    plist=$(launch_agent_path)

    if ! config_enabled '.cron.update_schedule.enabled'; then
        if [[ -f "$plist" ]]; then
            log_info "Removing scheduled updates (disabled in config)"
            unload_launch_agent "$plist"
            rm -f "$plist"
        else
            log_info "Scheduled updates are disabled in config"
        fi
        return 0
    fi

    local frequency time hour minute intervals
    frequency=$(config_get '.cron.update_schedule.frequency' daily)
    time=$(config_get '.cron.update_schedule.time' '09:00')

    if [[ ! "$time" =~ ^([01]?[0-9]|2[0-3]):([0-5][0-9])$ ]]; then
        log_error "Invalid cron.update_schedule.time: $time (use 24-hour HH:MM)"
        exit 1
    fi
    hour=$((10#${BASH_REMATCH[1]}))
    minute=$((10#${BASH_REMATCH[2]}))

    intervals=$(calendar_intervals "$frequency" "$hour" "$minute") || exit 1

    local log_dir="$HOME/Library/Logs/zapz"
    mkdir -p "$(dirname "$plist")" "$log_dir"

    cat > "$plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${ZAPZ_LAUNCH_AGENT_LABEL}</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>${ZAPZ_ROOT}/lib/maintenance.sh</string>
    </array>
    <key>StartCalendarInterval</key>
    <array>
${intervals}
    </array>
    <key>StandardOutPath</key>
    <string>${log_dir}/update.log</string>
    <key>StandardErrorPath</key>
    <string>${log_dir}/update.log</string>
</dict>
</plist>
EOF

    # Reload so schedule changes take effect
    unload_launch_agent "$plist"
    if launchctl bootstrap "gui/$(id -u)" "$plist"; then
        log_success "Scheduled $frequency updates at $(printf '%02d:%02d' "$hour" "$minute")"
    else
        log_warning "Could not load $plist; load it later with: launchctl bootstrap gui/$(id -u) $plist"
    fi
}
