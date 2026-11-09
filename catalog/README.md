# zapz catalog

What the setup wizard offers. `essentials.yml` applies to everyone; each file
in `personas/` and `packs/` is something a user can pick. The wizard merges
the essentials with every chosen persona and pack into one config.

## File format

```yaml
id: video                      # matches the file name
title: Video editing           # shown in the picker
tagline: Resolve, Final Cut…   # one line beside the title
order: 6                       # position in the picker
core:                          # installed whenever this is chosen
  - kind: cask
    name: iina
    label: IINA
picks:                         # follow-up questions
  - question: Which editors do you use?
    multi: true                # false = choose one
    items:
      - kind: mas
        id: 424389933
        label: Final Cut Pro
        note: paid; from the App Store
```

Quote values that contain a comma if you use YAML's inline `{…}` style: an
unquoted comma ends the value there.

## Item kinds

| kind | Fields | Goes to |
|---|---|---|
| `formula` | `name` | `homebrew.formulas` |
| `cask` | `name`, optional `then` (a follow-up for the checklist) | `homebrew.casks` |
| `mise` | `name` (one or more mise tool specs, space-separated) | `languages.tools` |
| `mas` | `id`, `label` | `apps.app_store` |
| `guided` | `label`, `url`, `note` | `checklist` (opened at the end) |
| `command` | `label`, `run`, `note` | `checklist` (shown to copy) |
| `none` | `label` | nothing (e.g. "Safari only") |

Optional on any item: `label` (defaults to `name`), `note` (shown in pickers),
`recommended: true` (ticked by default), `group` (a heading in pickers), and
`with` (a list of items that come along when this one is picked, e.g. the
`mise` formula with a mise tool).

Every Homebrew name is checked weekly by `.github/workflows/catalog.yml`
(`scripts/check-catalog.sh`), which fails if one is missing or disabled.
