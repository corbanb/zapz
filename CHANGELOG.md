# Changelog

All notable changes to zapz will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.0] - 2026-11-09

Set up a Mac for the way you work, not just for web development.

### Added
- Personas: pick any of software development, AI building, mobile apps,
  game development, data science, video editing, content & streaming,
  design and team collaboration. Each adds its apps and tools to the
  essentials, with a short screen of optional picks (★ marks the
  recommended ones; Enter takes them).
- Extras for anyone: meeting notes (Granola, Krisp, Meetily, Anarlog),
  voice dictation (Wispr Flow, Superwhisper, Aqua Voice, MacWhisper,
  VoiceInk, Handy, OpenWhispr, Buzz), local AI models (Ollama, LM Studio)
  and Raycast.
- Video editors to choose from: DaVinci Resolve, Final Cut Pro, Premiere
  Pro and Instagram's Edits. AI agent tools: Conductor, T3 Code, Paperclip,
  Codex, Antigravity CLI, OpenCode.
- A Security step: Touch ID for `sudo`, the firewall on, and a FileVault
  check.
- A Terminal & shell step: Ghostty (recommended), iTerm2, Warp or
  Terminal, and Oh My Zsh with autosuggestions, syntax highlighting and the
  Starship prompt (or just Starship, or nothing).
- Languages through mise (Node.js, Python, Bun, Go, Rust…), also updated by
  scheduled updates.
- App Store apps through `mas`, and a "Things only you can do" checklist
  at the end for App Store purchases, downloads behind a sign-up and app
  sign-ins, with links to open.
- A Screenshots folder setting.
- The preview shows who the setup is for, friendly app names, what will
  need you, and a time estimate.
- A weekly check that every app in the catalog is still in Homebrew.

### Changed
- The three presets are replaced by the persona catalog in `catalog/`.
- New configs use mise instead of nvm; `node.*` configs still work.
- The run ends with "Your Mac is ready" and the checklist first.
- Essentials add git-lfs, fzf, bat, eza, zoxide, btop, tlrc, mas, The
  Unarchiver, AppCleaner and a Nerd Font; Raycast is optional.
- Security settings are opt-in: configs from older versions (with no
  `security` section) are never changed; the wizard turns all three on.
- An unattended install (no terminal) gets the recommended config instead
  of the example; `--dry-run` before any config previews it.
- Follow-ups such as adding your SSH key to GitHub moved from "Next" into
  the checklist, with links.
- App Store installs need your administrator password (mas requires it),
  so zapz asks for it up front when an App Store app is missing. Scheduled
  updates run `mas upgrade` only when sudo works without a password.

## [0.2.0] - 2026-11-09

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
- The installer installs the latest release instead of the main branch; set
  `ZAPZ_REF=main` for the latest code.
- zapz downloads its own pinned, checksum-verified copy of yq instead of
  installing it with Homebrew, so your config can be read and previewed
  before anything is installed.
- Steps run in a new order so all questions come first: Command Line Tools,
  Git, SSH key, Homebrew, Node.js, macOS settings, scheduled updates, GitHub.
- The Node.js step is skipped when `node.versions` is empty.
- SSH keys are created with a passphrase prompt (stored in the Keychain)
  instead of an empty passphrase.
- Git aliases are only added if you haven't defined them yourself.
- Bun and Deno are installed through Homebrew formulas in the config.
- The example config installs `docker-desktop` (Homebrew renamed the
  `docker` cask).
- The example config uses Node.js 26 and 24 and drops the retired
  `homebrew/cask` and `homebrew/cask-fonts` taps.
- `macos.developer_mode` must be enabled explicitly before zapz runs
  `DevToolsSecurity`.

### Added
- A setup wizard: the installer asks for your name, email and a preset
  (Essentials, Web development, Minimal) and writes your config, then offers
  to start setup. Re-run it with `zapz --configure`. Presets are in
  `config/presets/`.
- A preview of everything zapz will install and change, and what you already
  have, before anything happens, with a "Continue?" prompt. `--dry-run` shows
  the preview only; `--yes` skips the question (required without a terminal).
- Questions come first: your password (asked once and kept fresh), git
  identity and SSH passphrase, so the long part runs unattended. A
  notification says when setup is done.
- Clearer output: numbered steps, one line per item with "already set" vs
  changed, installers run quietly with a spinner, and a summary of changes,
  problems and next steps. Full output goes to `~/Library/Logs/zapz/`.
  zapz exits with status 1 if anything failed.
- Backups: shell rc files, `~/.ssh/config` and your config are copied to
  `~/.local/state/zapz/backups/` before zapz edits them.
- GitHub CLI sign-in at the end of setup, which can upload your new SSH key.
- The installer starts the Xcode Command Line Tools install itself on a
  fresh Mac and waits for it, so the one-line install works on a new machine.
- Taps listed in `homebrew.taps` are trusted with `brew trust` (required
  for third-party taps since Homebrew 6).
- `git.config` for arbitrary `git config --global` options.
- `macos.finder.*`, `macos.dock.minimize-to-application` and
  `macos.developer_mode` settings.
- macOS version check: 14 or later required, with a warning below 15.
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
- Bash users now get Homebrew and nvm set up in `~/.bash_profile` (zsh users
  in `~/.zprofile` and `~/.zshrc`).
- A config with invalid YAML now stops setup with an error instead of
  skipping everything and reporting success.
- `zapz --update` works on installs pinned to a tag with `ZAPZ_REF`.
- The old cron job is removed when you run setup, so updates don't run twice.
- Setup gives up with a message if the Xcode Command Line Tools installer
  never finishes, instead of waiting forever.
- SSH setup works when Homebrew's openssh comes first on PATH: zapz calls
  Apple's `/usr/bin/ssh-add` for `--apple-use-keychain`, and generated SSH
  configs include `IgnoreUnknown UseKeychain` so non-Apple ssh accepts them.

### Removed
- `--force`, which had no effect.
- Support for macOS 12 and 13. zapz now needs macOS 14 or later and warns
  below 15, the oldest version Homebrew fully supports.
- `cron.terminal_update`, `cli.alias`, `cli.auto_alias` and
  `cli.update_notifications`, which were never implemented. Use
  `ZAPZ_DISABLE_UPDATE_CHECK=1` to turn off the update notice.

## [0.1.0] - 2024

### Added
- Initial release.
