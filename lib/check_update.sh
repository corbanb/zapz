#!/usr/bin/env bash

# Source version information
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/version.sh"

# Cache file for update checks
UPDATE_CACHE_FILE="${HOME}/.zapz_update_check"
UPDATE_CHECK_INTERVAL=86400  # 24 hours in seconds

# Check if we should run the update check
should_check_update() {
    # Create cache file if it doesn't exist
    if [[ ! -f "$UPDATE_CACHE_FILE" ]]; then
        echo "0" > "$UPDATE_CACHE_FILE"
        return 0
    fi

    local last_check
    last_check=$(cat "$UPDATE_CACHE_FILE")
    local current_time
    current_time=$(date +%s)
    local time_diff=$((current_time - last_check))

    # Return true if more than UPDATE_CHECK_INTERVAL has passed
    [[ $time_diff -ge $UPDATE_CHECK_INTERVAL ]]
}

# Update the timestamp of last check
update_check_timestamp() {
    date +%s > "$UPDATE_CACHE_FILE"
}

# Check for updates
if should_check_update; then
    # Get latest version from GitHub
    latest_version=$(curl -s https://api.github.com/repos/corbanb/zapz/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    
    if [[ "$latest_version" != "v${ZAPZ_VERSION}" ]]; then
        echo "🔔 A new version of zapz is available: ${latest_version}"
        echo "   Current version: v${ZAPZ_VERSION}"
        echo "   Run 'zapz --update' to update"
    fi
    
    # Update timestamp
    update_check_timestamp
fi 