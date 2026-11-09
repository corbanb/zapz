#!/usr/bin/env bash

# Cut a zapz release. Run it twice with the same version:
#
#   scripts/release.sh 0.3.1    # 1) opens a "chore(release): 0.3.1" PR that
#                               #    bumps lib/version.sh and the changelog
#   (merge the PR on GitHub)
#   scripts/release.sh 0.3.1    # 2) tags v0.3.1 on the merge commit, pushes
#                               #    the tag, waits for the Release workflow
#                               #    and prints the release URL
#
# Add --dry-run to see what would happen without changing anything.
#
# Both runs need a clean main that matches origin/main and a green CI run on
# the commit being released. Bash 3.2 compatible (macOS /bin/bash).

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DRY_RUN=0

die() { printf 'release: %s\n' "$*" >&2; exit 1; }
say() { printf '==> %s\n' "$*"; }

# Run a command, or just print it with --dry-run
run() {
    if [[ $DRY_RUN -eq 1 ]]; then
        printf '[dry-run] %s\n' "$*"
    else
        "$@"
    fi
}

usage() {
    sed -n '3,15p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
    printf '\nUsage: scripts/release.sh [--dry-run] X.Y.Z\n'
}

is_semver() {
    [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

# Print ZAPZ_VERSION from a version.sh file (path, or stdin if none)
read_version() {
    sed -n 's/^ZAPZ_VERSION="\([^"]*\)".*/\1/p' "${1:-/dev/stdin}" | head -n1
}

# Rewrite ZAPZ_VERSION in version file $1 to $2, writing to stdout
bump_version_file() {
    awk -v v="$2" '/^ZAPZ_VERSION="/ && !done { print "ZAPZ_VERSION=\"" v "\""; done=1; next } { print }' "$1"
}

# Move the body of "## [Unreleased]" in changelog $1 under a new
# "## [$2] - $3" heading, leaving an empty Unreleased section on top.
# Writes to stdout. Fails if there's no Unreleased heading or it's empty.
promote_changelog() {
    awk -v ver="$2" -v date="$3" '
        BEGIN { state = 0; found = 0; content = 0 }
        state == 0 && /^## \[Unreleased\][[:space:]]*$/ {
            found = 1; state = 1
            print; print ""
            print "## [" ver "] - " date
            next
        }
        state == 1 && /^## / { state = 2 }
        state == 1 && /[^[:space:]]/ { content = 1 }
        { print }
        END {
            if (!found) { print "no \"## [Unreleased]\" heading" > "/dev/stderr"; exit 2 }
            if (!content) { print "the Unreleased section is empty" > "/dev/stderr"; exit 3 }
        }
    ' "$1"
}

# Print the body of the "## [$2]" section of changelog $1
changelog_section() {
    awk -v ver="$2" '
        index($0, "## [" ver "]") == 1 { on = 1; next }
        on && /^## / { exit }
        on { print }
    ' "$1"
}

# Fail unless the CI workflow passed on commit $1. Waits if it's running.
require_green_ci() {
    local sha run_id status conclusion
    sha=$(git rev-parse "$1")
    # Match on headSha ourselves: `gh run list --commit` misses runs
    run_id=$(gh run list --workflow ci.yml --limit 100 --json databaseId,headSha \
        --jq "[.[] | select(.headSha == \"$sha\")][0].databaseId // empty")
    [[ -n "$run_id" ]] || die "no CI run found for ${sha:0:7}; push it or wait for CI to start"
    status=$(gh run view "$run_id" --json status --jq .status)
    if [[ "$status" != "completed" ]]; then
        say "CI is still running on ${sha:0:7}; waiting for it"
        gh run watch "$run_id" --exit-status >/dev/null || true
    fi
    conclusion=$(gh run view "$run_id" --json conclusion --jq .conclusion)
    [[ "$conclusion" == "success" ]] || \
        die "CI on ${sha:0:7} is '$conclusion', not green: $(gh run view "$run_id" --json url --jq .url)"
    say "CI is green on ${sha:0:7}"
}

# Clean tree, on main, and main matches origin/main
require_clean_main() {
    local branch
    branch=$(git rev-parse --abbrev-ref HEAD)
    [[ "$branch" == "main" ]] || die "switch to main first (on '$branch')"
    [[ -z "$(git status --porcelain)" ]] || die "working tree has uncommitted changes"
    git fetch --quiet --tags origin main
    [[ "$(git rev-parse HEAD)" == "$(git rev-parse origin/main)" ]] || \
        die "main isn't up to date with origin/main; run: git pull --ff-only"
}

# Step 1: bump files on a release branch and open a PR
open_release_pr() {
    local version="$1" current="$2" branch="release/v$1" today
    today=$(date +%Y-%m-%d)
    # Globals so the EXIT trap can still see them
    tmp_ver=""
    tmp_log=""

    if git ls-remote --exit-code --heads origin "$branch" >/dev/null 2>&1; then
        die "branch $branch already exists on GitHub; merge or close its PR first"
    fi

    tmp_ver=$(mktemp)
    tmp_log=$(mktemp)
    trap 'rm -f "$tmp_ver" "$tmp_log"' EXIT
    bump_version_file lib/version.sh "$version" > "$tmp_ver"
    if ! promote_changelog CHANGELOG.md "$version" "$today" > "$tmp_log"; then
        die "fix CHANGELOG.md: add your changes under '## [Unreleased]' first"
    fi
    [[ "$(read_version "$tmp_ver")" == "$version" ]] || die "couldn't bump lib/version.sh"

    say "Releasing $current -> $version"
    if [[ $DRY_RUN -eq 1 ]]; then
        diff -u lib/version.sh "$tmp_ver" || true
        diff -u CHANGELOG.md "$tmp_log" || true
    fi

    run git switch -c "$branch"
    if [[ $DRY_RUN -eq 0 ]]; then
        cat "$tmp_ver" > lib/version.sh
        cat "$tmp_log" > CHANGELOG.md
    fi
    run git commit -am "chore(release): $version"
    run git push -u origin "$branch"
    run gh pr create --base main --head "$branch" \
        --title "chore(release): $version" \
        --body "$(printf 'Release zapz %s.\n\n%s\n\nAfter merging, run `scripts/release.sh %s` on main to tag and publish it.\n' \
            "$version" "$(changelog_section "$tmp_log" "$version")" "$version")"
    run git switch main

    say "Next: merge the PR, then run: git pull --ff-only && scripts/release.sh $version"
}

# Step 2: tag the merged release commit, push the tag, wait for the release
tag_and_publish() {
    local version="$1" tag="v$1" sha run_id i

    # The squash/merge commit of the release PR, or else the last commit
    # that touched lib/version.sh
    sha=$(gh pr list --state merged --head "release/$tag" --limit 1 \
        --json mergeCommit --jq '.[0].mergeCommit.oid // empty')
    [[ -n "$sha" ]] || sha=$(git log -1 --format=%H -- lib/version.sh)
    git merge-base --is-ancestor "$sha" HEAD || die "${sha:0:7} isn't on main"
    [[ "$(git show "$sha:lib/version.sh" | read_version)" == "$version" ]] || \
        die "lib/version.sh at ${sha:0:7} isn't $version"

    require_green_ci "$sha"

    say "Tagging $tag at ${sha:0:7}"
    run git tag -a "$tag" "$sha" -m "zapz $version"
    run git push origin "refs/tags/$tag"
    [[ $DRY_RUN -eq 0 ]] || { say "(dry run) would wait for the Release workflow"; return 0; }

    say "Waiting for the Release workflow"
    run_id=""
    for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
        run_id=$(gh run list --workflow release.yml --branch "$tag" --limit 1 \
            --json databaseId --jq '.[0].databaseId // empty')
        [[ -n "$run_id" ]] && break
        sleep 3
    done
    [[ -n "$run_id" ]] || die "the Release workflow didn't start for $tag (tried $i times); check the Actions tab"
    gh run watch "$run_id" --exit-status >/dev/null || \
        die "the Release workflow failed: $(gh run view "$run_id" --json url --jq .url)"

    say "Released: $(gh release view "$tag" --json url --jq .url)"
}

main() {
    local version="" current
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run) DRY_RUN=1 ;;
            -h|--help) usage; exit 0 ;;
            -*) die "unknown option $1" ;;
            *) [[ -z "$version" ]] || die "one version only"; version="${1#v}" ;;
        esac
        shift
    done
    [[ -n "$version" ]] || { usage; exit 1; }
    is_semver "$version" || die "'$version' isn't X.Y.Z"
    command -v gh >/dev/null || die "needs the GitHub CLI (brew install gh)"

    cd "$PROJECT_ROOT"
    # shellcheck source=../lib/version.sh
    source lib/version.sh
    current="$ZAPZ_VERSION"

    require_clean_main
    if git rev-parse -q --verify "refs/tags/v$version" >/dev/null; then
        die "v$version is already tagged: $(gh release view "v$version" --json url --jq .url 2>/dev/null || echo 'no release yet')"
    fi

    if [[ "$current" == "$version" ]]; then
        tag_and_publish "$version"
    elif version_gt "$version" "$current"; then
        require_green_ci "$(git rev-parse HEAD)"
        open_release_pr "$version" "$current"
    else
        die "$version is older than the current version $current"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
