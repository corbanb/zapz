#!/usr/bin/env bash

# Check that every Homebrew formula and cask in catalog/ still exists, and
# report any that Homebrew has deprecated or disabled. Run weekly in CI so a
# retired app (like Arc) is caught before a user's setup tries to install it.
#
# Exits 1 if a name is missing or disabled; deprecations are warnings.

set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RAW="https://raw.githubusercontent.com/Homebrew"
missing=0
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# Where a name's definition lives in Homebrew's repositories
source_url() {
    local kind="$1" name="$2" letter
    if [[ "$kind" == cask && "$name" == font-* ]]; then
        letter="${name#font-}"
        echo "$RAW/homebrew-cask/main/Casks/font/font-${letter:0:1}/$name.rb"
    elif [[ "$kind" == cask ]]; then
        echo "$RAW/homebrew-cask/main/Casks/${name:0:1}/$name.rb"
    else
        echo "$RAW/homebrew-core/main/Formula/${name:0:1}/$name.rb"
    fi
}

# Every Homebrew item in the catalog, as "kind name" (tap-qualified formulas
# like user/tap/name live in other repositories and are skipped)
yq ea '[.core // [], ((.picks // [])[].items), ((.core // [], ((.picks // [])[].items))[] | .with // [])]
        | flatten | .[] | select(.kind == "formula" or .kind == "cask") | .kind + " " + .name' \
    "$PROJECT_ROOT"/catalog/essentials.yml "$PROJECT_ROOT"/catalog/personas/*.yml \
    "$PROJECT_ROOT"/catalog/packs/*.yml | grep -v '/' | sort -u > "$work/items"

checked=0
while read -r kind name; do
    file="$work/$kind-$name.rb"
    code=$(curl -s --retry 2 -o "$file" -w '%{http_code}' "$(source_url "$kind" "$name")")
    checked=$((checked + 1))
    if [[ "$code" != 200 ]]; then
        echo "::error::$kind '$name' was not found in Homebrew (renamed or removed?)"
        missing=1
        continue
    fi
    if line=$(grep -m1 -E '^[[:space:]]*disable!' "$file"); then
        echo "::error::$kind '$name' is disabled by Homebrew: ${line#"${line%%[![:space:]]*}"}"
        missing=1
    elif line=$(grep -m1 -E '^[[:space:]]*deprecate!' "$file"); then
        echo "::warning::$kind '$name' is deprecated by Homebrew: ${line#"${line%%[![:space:]]*}"}"
    fi
done < "$work/items"

echo "Checked $checked Homebrew names in catalog/"
exit "$missing"
