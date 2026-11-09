#!/usr/bin/env bash

# Reading the persona catalog (catalog/*.yml) and collecting what the user
# picks into one config. See catalog/README.md for the file format.

# Separates fields inside one selection entry: a character that can't appear
# in a title, URL or command (a "|" can, as in "curl … | sh")
ZAPZ_SEP=$'\x1f'

catalog_dir() {
    printf '%s\n' "${ZAPZ_CATALOG_DIR:-$ZAPZ_ROOT/catalog}"
}

# Print "file<TAB>title<TAB>tagline" for each persona or pack, in order.
# Usage: catalog_entries personas|packs
catalog_entries() {
    local dir file
    dir="$(catalog_dir)/$1"
    for file in "$dir"/*.yml; do
        [[ -f "$file" ]] || continue
        printf '%s\t%s\n' "$(yq e '.order // 99' "$file")" "$file"
    done | sort -n | while IFS=$'\t' read -r _ file; do
        printf '%s\t%s\t%s\n' "$file" "$(yq e '.title' "$file")" "$(yq e '.tagline // ""' "$file")"
    done
}

# Print one tab-separated row per item at a YAML path (e.g. .core or
# .picks[0].items): kind name label id url run note then recommended group
# with-count. Empty fields are "-" so tab-splitting keeps their positions.
catalog_items() {
    yq e "($2 // [])[] | [
        .kind,
        (.name // \"-\"),
        (.label // .name // \"-\"),
        (.id // \"-\" | tostring),
        (.url // \"-\"),
        (.run // \"-\"),
        (.note // \"-\"),
        (.then // \"-\"),
        (.recommended // false | tostring),
        (.group // \"-\"),
        (.with // [] | length | tostring)
    ] | @tsv" "$1"
}

# --- what the user picked ------------------------------------------------

catalog_reset_selection() {
    SEL_FORMULAS=()
    SEL_CASKS=()
    SEL_MISE=()
    SEL_MAS=()
    SEL_CHECKLIST=()
}

# Add one item (the fields from a catalog_items row) to the selection
catalog_select() {
    local kind="$1" name="$2" label="$3" id="$4" url="$5" run="$6" note="$7" follow="$8"
    local tool
    case "$kind" in
        formula) SEL_FORMULAS+=("$name") ;;
        cask) SEL_CASKS+=("$name") ;;
        mise)
            for tool in $name; do
                SEL_MISE+=("$tool")
            done
            ;;
        mas) SEL_MAS+=("$label${ZAPZ_SEP}$id") ;;
        guided) SEL_CHECKLIST+=("Download $label${ZAPZ_SEP}$url${ZAPZ_SEP}-${ZAPZ_SEP}$note") ;;
        command) SEL_CHECKLIST+=("$label${ZAPZ_SEP}-${ZAPZ_SEP}$run${ZAPZ_SEP}$note") ;;
        none) ;;
    esac
    if [[ "$follow" != "-" ]]; then
        SEL_CHECKLIST+=("$follow${ZAPZ_SEP}-${ZAPZ_SEP}-${ZAPZ_SEP}-")
    fi
}

# Select every item at a path, plus anything each one brings along (`with`)
# Usage: catalog_select_all <file> <path>
catalog_select_all() {
    local file="$1" path="$2" i=0 row
    local kind name label id url run note follow recommended group with
    while IFS=$'\t' read -r kind name label id url run note follow recommended group with; do
        [[ -n "$kind" ]] || continue
        catalog_select "$kind" "$name" "$label" "$id" "$url" "$run" "$note" "$follow"
        if [[ "$with" != 0 ]]; then
            catalog_select_all "$file" "${path}[$i].with"
        fi
        i=$((i + 1))
    done < <(catalog_items "$file" "$path")
}

# Select the items at the given 1-based positions of a list
# Usage: catalog_select_numbers <file> <path> <numbers...>
catalog_select_numbers() {
    local file="$1" path="$2" n
    shift 2
    for n in "$@"; do
        catalog_select_all "$file" "${path}[$((n - 1))] | [.]"
    done
}

# Lines of the selection, de-duplicated in order
_unique_lines() {
    awk 'NF && !seen[$0]++'
}

# Write the selection into a config file (lists are merged and de-duplicated)
# Usage: catalog_write_selection <config file>
catalog_write_selection() {
    local config="$1" entry title url cmd note
    ZAPZ_W_LIST=$(printf '%s\n' ${SEL_FORMULAS[@]+"${SEL_FORMULAS[@]}"} | _unique_lines) \
        yq -i '.homebrew.formulas = ((.homebrew.formulas // []) + (strenv(ZAPZ_W_LIST) | split("\n") | map(select(. != "")))) | .homebrew.formulas |= unique' "$config"
    ZAPZ_W_LIST=$(printf '%s\n' ${SEL_CASKS[@]+"${SEL_CASKS[@]}"} | _unique_lines) \
        yq -i '.homebrew.casks = ((.homebrew.casks // []) + (strenv(ZAPZ_W_LIST) | split("\n") | map(select(. != "")))) | .homebrew.casks |= unique' "$config"
    ZAPZ_W_LIST=$(printf '%s\n' ${SEL_MISE[@]+"${SEL_MISE[@]}"} | _unique_lines) \
        yq -i '.languages.tools = ((.languages.tools // []) + (strenv(ZAPZ_W_LIST) | split("\n") | map(select(. != "")))) | .languages.tools |= unique' "$config"

    for entry in ${SEL_MAS[@]+"${SEL_MAS[@]}"}; do
        ZAPZ_W_NAME="${entry%"$ZAPZ_SEP"*}" ZAPZ_W_ID="${entry##*"$ZAPZ_SEP"}" \
            yq -i '.apps.app_store += [{"name": strenv(ZAPZ_W_NAME), "id": (strenv(ZAPZ_W_ID) | tonumber)}] | .apps.app_store |= unique_by(.id)' "$config"
    done

    for entry in ${SEL_CHECKLIST[@]+"${SEL_CHECKLIST[@]}"}; do
        IFS="$ZAPZ_SEP" read -r title url cmd note <<< "$entry"
        ZAPZ_W_TITLE="$title" ZAPZ_W_URL="$url" ZAPZ_W_CMD="$cmd" ZAPZ_W_NOTE="$note" yq -i '
            .checklist += [{"title": strenv(ZAPZ_W_TITLE)}
                + (strenv(ZAPZ_W_URL) | select(. != "-") | {"url": .})
                + (strenv(ZAPZ_W_CMD) | select(. != "-") | {"command": .})
                + (strenv(ZAPZ_W_NOTE) | select(. != "-") | {"note": .})]
            | .checklist |= unique_by(.title)' "$config"
    done
}
