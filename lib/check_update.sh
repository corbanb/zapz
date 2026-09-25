# shellcheck shell=bash
#
# Prints a one-line notice when a newer zapz release is available.
# Sourced from the user's shell rc (zsh or bash), so it must be portable,
# define nothing permanent, and never make the prompt wait on the network:
# the latest version is fetched in the background at most once a day and
# read back from a cache file on later shells.
#
# Disable with: export ZAPZ_DISABLE_UPDATE_CHECK=1

_zapz_update_notice() {
    [ -z "${ZAPZ_DISABLE_UPDATE_CHECK:-}" ] || return 0

    local root cache_dir cache current latest newest
    root="${ZAPZ_HOME:-$HOME/.local/share/zapz}"
    cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zapz"
    cache="$cache_dir/latest_version"

    current=$(sed -n 's/^ZAPZ_VERSION="\(.*\)"$/\1/p' "$root/lib/version.sh" 2>/dev/null)
    [ -n "$current" ] || return 0

    # Refresh when the cache is missing or older than a day. Touch it first
    # so shells opened while the fetch runs don't start another one.
    if [ ! -f "$cache" ] || [ -n "$(find "$cache" -mmin +1440 2>/dev/null)" ]; then
        mkdir -p "$cache_dir" && touch "$cache"
        (
            (
                curl -fsS --max-time 5 "https://api.github.com/repos/corbanb/zapz/releases/latest" \
                    | sed -n 's/.*"tag_name": *"v\{0,1\}\([^"]*\)".*/\1/p' > "$cache.tmp" \
                    && [ -s "$cache.tmp" ] && mv "$cache.tmp" "$cache"
                rm -f "$cache.tmp"
            ) &
        ) >/dev/null 2>&1
    fi

    latest=$(cat "$cache" 2>/dev/null)
    [ -n "$latest" ] && [ "$latest" != "$current" ] || return 0

    newest=$(printf '%s\n%s\n' "$current" "$latest" | sort -t. -k1,1n -k2,2n -k3,3n | tail -n1)
    if [ "$newest" = "$latest" ]; then
        printf 'zapz %s is available (you have %s). Run: zapz --update\n' "$latest" "$current"
    fi
}

_zapz_update_notice
unset -f _zapz_update_notice
