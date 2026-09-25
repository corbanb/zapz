#!/usr/bin/env bash

ZAPZ_VERSION="0.1.0"
ZAPZ_MIN_MACOS_VERSION="12.0"  # Monterey
ZAPZ_REPO_SLUG="corbanb/zapz"
ZAPZ_RELEASE_URL="https://github.com/${ZAPZ_REPO_SLUG}/releases"

# Succeeds if dotted version $1 is newer than $2 (a leading "v" is ignored).
# Uses sort -n per field because older macOS sort has no -V.
version_gt() {
    local a="${1#v}" b="${2#v}"
    [[ "$a" != "$b" ]] || return 1
    [[ "$(printf '%s\n%s\n' "$a" "$b" | sort -t. -k1,1n -k2,2n -k3,3n | tail -n1)" == "$a" ]]
}
