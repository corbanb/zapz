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
  version.sh
  check_update.sh         Update notice sourced from users' shells (must work in zsh and bash)
  maintenance.sh          Run by launchd for scheduled updates
  modules/*.sh            One setup step each: xcode, git, ssh (and GitHub), homebrew, node, macos, schedule
config/
  default.yml.example     Every option, documented
  presets/*.yml           What the wizard starts from: essentials, webdev, minimal
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
  and confirmation (`--dry-run`, `--yes`, no terminal), the wizard and presets,
  backups, the pinned yq download, and the output layer (summary counts, exit
  status, `NO_COLOR`).

Tests use a temporary `HOME` and stub commands such as `brew`, `defaults`,
`launchctl` and `sudo` (see `test/helpers.sh`). They never touch your real
system, and they run on Linux too.

When you change a module, add a test to `test/test_modules.sh` that runs the
module and checks the result. Where it matters, run it twice and check that
the second run changes nothing and reports "already set". If you change what
a step does, update the preview in `lib/plan.sh` to match, and the presets and
`config/default.yml.example` if you add a config option.

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
    `[3/8] SSH key`).
  - `ui_item <state> <label> [detail]` for one result line, where state is
    `changed`, `existing` (already set), `skipped` or `failed`. These feed the
    summary counts, and `failed` items are listed under "Problems" and make
    zapz exit 1.
  - `run_quiet [--housekeeping] <label> <command> [args...]` to run a noisy
    command: it shows a spinner, sends the output to the log, prints one
    result line, and shows the end of the output only if it fails. With
    `--housekeeping`, success isn't counted as a change (e.g. `brew update`).
  - `add_next_step "..."` for something the user has to do after the run; it
    appears under "Next" in the summary.
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

1. Bump `ZAPZ_VERSION` in `lib/version.sh` and add a `CHANGELOG.md` entry.
2. After merging, tag the commit: `git tag v0.2.0 && git push origin v0.2.0`.

The release workflow checks that the tag matches `lib/version.sh`, then
publishes a GitHub release.

## License

By contributing, you agree that your contributions will be licensed under the
MIT License.
