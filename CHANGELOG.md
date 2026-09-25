# Changelog

All notable changes to zapz will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

The first version that installs and runs end to end on a fresh Mac.

### Changed
- zapz installs to `~/.local/share/zapz` (was `~/.local/bin/mac-setup`) and
  only needs git to install. Set `ZAPZ_REF` to install a specific tag or
  branch.
- Scheduled updates use a launchd LaunchAgent instead of cron and log to
  `~/Library/Logs/zapz/update.log`. The `cron.update_schedule` config keys
  are unchanged; weekly schedules accept several `days`.
- `--skip-cron` is now `--skip-schedule` (the old name still works).
- `--update` updates zapz with `git pull` instead of only checking.
- SSH keys are created with a passphrase prompt (stored in the Keychain)
  instead of an empty passphrase.
- Git aliases are only added if you haven't defined them yourself.
- Bun and Deno are installed through Homebrew formulas in the config.
- The example config uses Node.js 24 and 22 and drops the retired
  `homebrew/cask` and `homebrew/cask-fonts` taps.
- `macos.developer_mode` must be enabled explicitly before zapz runs
  `DevToolsSecurity`.

### Added
- `git.config` for arbitrary `git config --global` options.
- `macos.finder.*`, `macos.dock.minimize-to-application` and
  `macos.developer_mode` settings.
- macOS version check (12 or later).
- Behavioral test suite, run in CI on Ubuntu and macOS (bash 3.2).

### Fixed
- The installer cloned a placeholder repository URL.
- The `zapz` command couldn't find its files when run through its symlink.
- Re-running setup failed at the Node.js step.
- Empty `git.user` values erased your existing git identity; missing keys
  were written as the string `null`.
- `enabled: false` was ignored for scheduled updates.
- Setup crashed on macOS's bash 3.2 with weekly schedules.
- Shell config lines were appended to `~/.zshrc` and `~/.zprofile` on every
  run.
- The update notice failed in zsh, overwrote shell variables, and blocked new
  terminals on a network request.
- One failed Homebrew package (or an app installed outside Homebrew) aborted
  the whole setup.
- An existing `~/.ssh/config` never got a `github.com` entry.
- Unknown options and missing option values crashed with "command not found".
- Gist configs were downloaded to a fixed, predictable `/tmp` path.

### Removed
- `--force`, which had no effect.
- `cron.terminal_update`, `cli.alias`, `cli.auto_alias` and
  `cli.update_notifications`, which were never implemented. Use
  `ZAPZ_DISABLE_UPDATE_CHECK=1` to turn off the update notice.

## [0.1.0] - 2024

### Added
- Initial release.
