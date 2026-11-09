# Contributing to zapz

Thanks for helping out! This covers setting up, testing, and opening a pull
request.

## Setup

```bash
git clone https://github.com/corbanb/zapz.git
cd zapz
brew install yq shellcheck yamllint

# Optional: lint and run the fast tests before every commit
./scripts/setup-hooks.sh
```

## Project layout

```text
setup.sh                  The `zapz` command: parses options, previews, confirms, runs modules in order
install.sh                The curl | bash installer (installs, runs the wizard, offers to run setup)
lib/
  utils.sh                Config helpers (config_get, config_list, ...), prompts, backups, yq download
  logging.sh              Output: step headers, result lines, run_quiet, the summary
  plan.sh                 The preview shown before anything changes (read-only)
  configure.sh            The setup wizard (install.sh and `zapz --configure`)
  catalog.sh              Reads catalog/ and turns the wizard's picks into config entries
  version.sh
  check_update.sh         Update notice sourced from users' shells (must work in zsh and bash)
  maintenance.sh          Run by launchd for scheduled updates
  modules/*.sh            One setup step each: xcode, security, git, ssh (and GitHub), homebrew,
                          languages (mise), node (older nvm configs), terminal (and shell),
                          appstore, macos, schedule
catalog/
  README.md               The file format and item kinds
  base.yml                What every wizard-written config starts from
  essentials.yml          What every Mac gets
  personas/*.yml          The "What will you use this Mac for?" choices
  packs/*.yml             The optional extras
config/
  default.yml.example     Every option, documented
scripts/
  check-catalog.sh        Checks every Homebrew name in catalog/ still exists (weekly in CI)
test/
```

## Testing

```bash
./test/run_tests.sh          # everything
bash test/test_modules.sh    # one suite
```

- `test/test.sh`: syntax, shellcheck, bash 3.2 compatibility and config
  loading.
- `test/test_modules.sh`: runs each module in a sandbox and checks what it
  changed.
- `test/test_install.sh`: runs `install.sh` in a sandbox. It sets
  `ZAPZ_SOURCE` to the checkout so the installer copies it instead of
  cloning from GitHub.
- `test/test_experience.sh`: the first-run experience end to end: the preview
  and confirmation (`--dry-run`, `--yes`, no terminal), the wizard (with
  scripted answers) and catalog validity, backups, the pinned yq download, and the output layer (summary counts, exit
  status, `NO_COLOR`).

Tests use a temporary `HOME` and stub commands such as `brew`, `defaults`,
`launchctl` and `sudo` (see `test/helpers.sh`). They never touch your real
system, and they run on Linux too.

When you change a module, add a test to `test/test_modules.sh` that runs the
module and checks the result. Where it matters, run it twice and check that
the second run changes nothing and reports "already set". If you change what
a step does, update the preview in `lib/plan.sh` to match. If you add a config
option, document it in `config/default.yml.example` and, if the wizard should
set it, `catalog/base.yml` or `lib/configure.sh`.

## Adding to the catalog

The wizard's personas, extras and their questions live in `catalog/`, so most
"please add app X" changes are YAML only. See
[`catalog/README.md`](catalog/README.md) for the format.

- **An item:** add it to a persona's or pack's `core` (always installed) or to
  one of its `picks` questions. Use the right `kind`: `formula` or `cask` for
  Homebrew, `mise` for languages, `mas` for App Store apps (with its `id`),
  `guided` for downloads zapz can't install (with a `url`), or `command` for
  something the user runs (with `run`). Give it a `label` and a short `note`,
  add `then` for a follow-up the user must do (like signing in), and mark at
  most a few `recommended: true`.
- **A persona or pack:** add a file to `catalog/personas/` or `catalog/packs/`
  with a unique `id` that matches the file name, a `title`, a one-line
  `tagline` and an `order`.
- Check every Homebrew name exists: `./scripts/check-catalog.sh` (needs
  network access). The `Catalog` workflow runs it on catalog changes and
  weekly, and fails if a name is missing or disabled.
- Update `docs/docs/personas/index.md`, which lists every item.

## Code guidelines

- **bash 3.2.** zapz runs under macOS's `/bin/bash`, so no associative
  arrays, `${var,,}`, `mapfile` or `&>>`. `test/test.sh` checks for these, and
  CI runs the suite under `/bin/bash` on macOS.
- **Safe to re-run.** Compare the config with the current state before
  changing anything, and report what's already in place as `existing`, so a
  second run says "already set" instead of redoing work. Write shell rc
  changes with `write_managed_block` instead of appending, and call
  `backup_file` before editing any other user file.
- **Output.** Report results with the helpers in `lib/logging.sh` rather
  than printing your own lines:
  - `log_header "Title"` once at the start of a step (prints e.g.
    `[3/10] SSH key`). The steps that run depend on the config, so the total
    varies; add a new step to the list in `main` in `setup.sh`.
  - `ui_item <state> <label> [detail]` for one result line, where state is
    `changed`, `existing` (already set), `skipped` or `failed`. These feed the
    summary counts, and `failed` items are listed under "Problems" and make
    zapz exit 1.
  - `run_quiet [--housekeeping] <label> <command> [args...]` to run a noisy
    command: it shows a spinner, sends the output to the log, prints one
    result line, and shows the end of the output only if it fails. With
    `--housekeeping`, success isn't counted as a change (e.g. `brew update`).
  - `add_checklist "title" [url] [command]` for something only the user can
    do (a sign-in, a download, a command to run). It appears in the numbered
    "Things only you can do" list at the end, which offers to open the links.
  - `add_next_step "..."` for a general next step; it appears under "Next" in
    the summary.
- **Questions up front.** Setup asks everything (confirmation, git identity,
  password) before the steps start. Don't add prompts in the middle of a
  module; if one is unavoidable, read from `$ZAPZ_PROMPT_FD` and handle there
  being no terminal.
- **Config.** Read values with `config_get`, `config_list` and
  `config_enabled`. They treat missing keys as unset, so users can delete any
  section.
- **Don't abort on one bad package.** Report it with `ui_item failed` (or let
  `run_quiet` do it) and continue, the way `setup_homebrew` does.
- Follow the [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html),
  and keep shellcheck and yamllint clean.

## Pull requests

- Use a [Conventional Commits](https://www.conventionalcommits.org) title,
  like `feat: add fish shell support` or `fix(ssh): keep existing config`. CI
  checks it.
- Describe what changed and how you tested it.
- Update the README and `docs/` if you change behavior or config options.

## Releasing

Releases are cut with `scripts/release.sh`, run from a clean, up-to-date
`main` with the GitHub CLI signed in. It takes two runs with the same version:

```bash
scripts/release.sh --dry-run 0.3.1   # preview: shows the diffs and commands
scripts/release.sh 0.3.1             # 1) opens a "chore(release): 0.3.1" PR
# ...merge that PR on GitHub...
git pull --ff-only
scripts/release.sh 0.3.1             # 2) tags v0.3.1 and publishes the release
```

1. The first run checks that CI passed on `main`, sets `ZAPZ_VERSION` in
   `lib/version.sh`, moves everything under `## [Unreleased]` in
   `CHANGELOG.md` to `## [0.3.1] - <today>`, and opens a PR from
   `release/v0.3.1` (`main` is protected, so the bump goes through a PR).
2. The second run, once `main` has the new version, checks CI on the merge
   commit, tags it `v0.3.1`, pushes the tag, waits for the Release workflow
   and prints the release URL.

Add changes under `## [Unreleased]` as you go; the script refuses to release
an empty section. Tags always start with `v` (`v0.3.1`): the Release workflow
only runs for `v*` tags and checks the tag matches `lib/version.sh`, and
`zapz --update` only looks at `v` tags. The workflow attaches `install.sh` and
marks the release Latest, which is what `install.sh` installs.

## License

By contributing, you agree that your contributions will be licensed under the
MIT License.
