#!/usr/bin/env bash

setup_cron_jobs() {
    log_header "Setting up maintenance cron jobs"
    
    # Check if updates are enabled
    if ! yq e '.cron.update_schedule.enabled' "$CONFIG_FILE" &>/dev/null; then
        log_info "Automatic updates are disabled in config"
        return 0
    fi
    
    # Create the update script
    local update_script="$HOME/.local/bin/mac-setup-update"
    local script_dir
    script_dir="$(dirname "$update_script")"
    
    # Create directory if it doesn't exist
    mkdir -p "$script_dir"
    
    # Create the last update timestamp file
    local timestamp_file="$HOME/.local/state/mac-setup-last-update"
    mkdir -p "$(dirname "$timestamp_file")"
    touch "$timestamp_file"
    
    # Create the update script
    cat > "$update_script" << 'EOF'
#!/usr/bin/env bash

# Script to update development environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$HOME/.local/log/mac-setup-update.log"
TIMESTAMP_FILE="$HOME/.local/state/mac-setup-last-update"
mkdir -p "$(dirname "$LOG_FILE")"

{
    echo "=== Update started at $(date) ==="
    
    # Update timestamp
    date +%s > "$TIMESTAMP_FILE"
    
    # Update Homebrew
    echo "Updating Homebrew..."
    brew update
    brew upgrade
    brew cleanup
    
    # Run brew doctor
    echo "Running brew doctor..."
    if ! brew doctor; then
        # Send notification if there are issues
        osascript -e 'display notification "Brew doctor found issues. Check the log file." with title "Mac Setup Update"'
    fi
    
    # Update npm packages
    echo "Updating global npm packages..."
    npm update -g
    
    # Update App Store apps
    echo "Updating App Store apps..."
    if command -v mas &>/dev/null; then
        mas upgrade
    fi
    
    echo "=== Update completed at $(date) ==="
} >> "$LOG_FILE" 2>&1

# Send success notification
osascript -e 'display notification "Daily update completed successfully" with title "Mac Setup Update"'
EOF
    
    # Make the script executable
    chmod +x "$update_script"
    
    # Generate cron schedule based on configuration
    local frequency
    local time
    local days
    frequency=$(yq e '.cron.update_schedule.frequency' "$CONFIG_FILE")
    time=$(yq e '.cron.update_schedule.time' "$CONFIG_FILE")
    
    # Convert time to cron format
    local hour minute
    hour=$(echo "$time" | cut -d: -f1)
    minute=$(echo "$time" | cut -d: -f2)
    
    # Generate cron expression based on frequency
    local cron_schedule
    case "$frequency" in
        "daily")
            cron_schedule="$minute $hour * * *"
            ;;
        "weekly")
            days=$(yq e '.cron.update_schedule.days[]' "$CONFIG_FILE" | head -1)
            cron_schedule="$minute $hour * * $(get_day_number "$days")"
            ;;
        "monthly")
            cron_schedule="$minute $hour 1 * *"
            ;;
        *)
            log_error "Invalid update frequency: $frequency"
            exit 1
            ;;
    esac
    
    # Create the cron job
    log_info "Creating cron job..."
    (crontab -l 2>/dev/null || true; echo "$cron_schedule $update_script") | sort - | uniq - | crontab -
    
    # Setup terminal update check if enabled
    if yq e '.cron.terminal_update.enabled' "$CONFIG_FILE" &>/dev/null; then
        setup_terminal_update
    fi
    
    log_success "Cron jobs setup completed"
}

# Helper function to convert day name to number
get_day_number() {
    case "${1,,}" in
        "sunday") echo "0" ;;
        "monday") echo "1" ;;
        "tuesday") echo "2" ;;
        "wednesday") echo "3" ;;
        "thursday") echo "4" ;;
        "friday") echo "5" ;;
        "saturday") echo "6" ;;
        *) echo "0" ;;
    esac
}

# Setup terminal update check
setup_terminal_update() {
    local shell_rc
    local check_script
    
    # Determine shell configuration file
    if [[ "$SHELL" == */zsh ]]; then
        shell_rc="$HOME/.zshrc"
    elif [[ "$SHELL" == */bash ]]; then
        shell_rc="$HOME/.bashrc"
    else
        log_warning "Unsupported shell for terminal updates"
        return 1
    fi
    
    # Create the update check function
    check_script="$HOME/.local/bin/mac-setup-check"
    cat > "$check_script" << 'EOF'
#!/usr/bin/env bash

TIMESTAMP_FILE="$HOME/.local/state/mac-setup-last-update"
UPDATE_SCRIPT="$HOME/.local/bin/mac-setup-update"
MIN_INTERVAL=$(yq e '.cron.terminal_update.frequency' "$CONFIG_FILE")

# Check if it's time to update
if [[ -f "$TIMESTAMP_FILE" ]]; then
    last_update=$(cat "$TIMESTAMP_FILE")
    now=$(date +%s)
    elapsed=$((now - last_update))
    
    if ((elapsed >= MIN_INTERVAL)); then
        echo "Running system updates..."
        "$UPDATE_SCRIPT"
    fi
fi
EOF
    
    chmod +x "$check_script"
    
    # Add alias and update check to shell config
    local alias_name
    alias_name=$(yq e '.cli.alias' "$CONFIG_FILE")
    
    if ! grep -q "alias $alias_name=" "$shell_rc"; then
        {
            echo "# macOS setup tool alias and update check"
            echo 'export PATH="$HOME/.local/bin:$PATH"'
        } >> "$shell_rc"
    fi
} 