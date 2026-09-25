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
setup.sh                  The `zapz` command: parses options, runs modules in order
install.sh                The curl | bash installer
lib/
  utils.sh                Config helpers (config_get, config_list, ...) and shared functions
  logging.sh, version.sh
  check_update.sh         Update notice sourced from users' shells (must work in zsh and bash)
  maintenance.sh          Run by launchd for scheduled updates
  modules/*.sh            One setup step each: xcode, homebrew, git, ssh, node, macos, schedule
config/default.yml.example
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
- `test/test_install.sh`: runs `install.sh` in a sandbox.

Tests use a temporary `HOME` and stub commands such as `brew`, `defaults`,
`launchctl` and `sudo` (see `test/helpers.sh`). They never touch your real
system, and they run on Linux too.

When you change a module, add a test to `test/test_modules.sh` that runs the
module and checks the result. Where it matters, run it twice and check that
nothing was duplicated.

## Code guidelines

- **bash 3.2.** zapz runs under macOS's `/bin/bash`, so no associative
  arrays, `${var,,}`, `mapfile` or `&>>`. `test/test.sh` checks for these, and
  CI runs the suite under `/bin/bash` on macOS.
- **Safe to re-run.** Check before installing. Write shell rc changes with
  `write_managed_block` instead of appending.
- **Config.** Read values with `config_get`, `config_list` and
  `config_enabled`. They treat missing keys as unset, so users can delete any
  section.
- **Don't abort on one bad package.** Report it and continue, the way
  `setup_homebrew` does.
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
