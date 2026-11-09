<div align="center">

# ⚡️ zapz

Set up a Mac for development with one command, from one YAML file.

[![Version](https://img.shields.io/github/v/release/corbanb/zapz?include_prereleases&label=version)](https://github.com/corbanb/zapz/releases)
[![CI](https://github.com/corbanb/zapz/actions/workflows/ci.yml/badge.svg)](https://github.com/corbanb/zapz/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![macOS](https://img.shields.io/badge/macOS-14%2B-brightgreen)](#requirements)

[📖 Documentation](https://corbanb.github.io/zapz) | [🚀 Quick Start](#-quick-start) | [⚙️ Configuration](#%EF%B8%8F-configuration)

</div>

---

## 🎯 Overview

`zapz` turns a fresh Mac into a working development machine: Homebrew and your
apps, git, an SSH key for GitHub, Node.js, sensible macOS settings, and
scheduled updates.

It's built to be calm and trustworthy:

- **No YAML to start.** A short wizard asks your name, email and what you want
  (Essentials, Web development or Minimal) and writes the config for you.
- **See it before it happens.** zapz shows exactly what it will install and
  change, and what you already have, then asks before touching anything. Try
  `zapz --dry-run` any time.
- **Questions first, then hands-off.** Your password, git identity and SSH
  passphrase are asked up front; the long part runs without you, and you get
  a notification when it's done.
- **Safe to run again.** Anything already installed or set is left alone, and
  shell and SSH files are backed up before zapz edits them.
- **Clear results.** One line per item, a summary of what changed and what
  needs attention, and a full log for when something goes wrong.

## ✨ What it sets up

1. **Command Line Tools** (Apple's developer tools, which include git)
2. **Git**: name, email, editor, default branch and other `git config` options
3. **SSH key**: an ed25519 key protected by a passphrase that macOS keeps in
   your Keychain, plus a `github.com` entry in `~/.ssh/config`
4. **Homebrew** and your packages and apps. A package that fails is listed in
   the summary instead of stopping setup.
5. **Node.js** via [nvm](https://github.com/nvm-sh/nvm): versions, a default and
   global npm packages
6. **macOS settings**: Dock, key repeat and Finder
7. **Scheduled updates**: a launchd job that runs `brew upgrade`,
   `npm update -g` and `mas upgrade` on your schedule
8. **GitHub**: sign in with the GitHub CLI, which can upload your new SSH key
   for you

## 🚀 Quick Start

### Requirements

- macOS 14 (Sonoma) or later; macOS 15 or later is recommended (Homebrew's
  fully supported versions). Tested on macOS 15, 26 and 27.
- An administrator account (Homebrew and apps need your password once).

That's it. On a new Mac the installer first opens Apple's Command Line Tools
dialog; click **Install** and it carries on when that finishes.

### Install

```bash
curl -fsSL https://raw.githubusercontent.com/corbanb/zapz/main/install.sh | bash
```

The installer:

1. installs the latest zapz release to `~/.local/share/zapz` and adds the
   `zapz` command to `~/.local/bin` (it edits `~/.zshrc`, or `~/.bash_profile`
   for bash, inside a clearly marked block);
2. asks a few questions and writes your config;
3. offers to preview and run setup right away.

Prefer to read it first? Download it, look, then run it:

```bash
curl -fsSLO https://raw.githubusercontent.com/corbanb/zapz/main/install.sh
less install.sh
bash install.sh
```

To install a specific release or branch, set `ZAPZ_REF` (for example
`ZAPZ_REF=v0.2.0` or `ZAPZ_REF=main`).

### What a run looks like

```text
  ⚡ zapz 0.2.0 · macOS 27.2 · Apple Silicon

  Here's what zapz will do:

  Tools      Command Line Tools: already installed
  Homebrew   install Homebrew
  Packages   git, gh, jq, ripgrep, fd, tree, wget, oven-sh/bun/bun, deno
  Apps       visual-studio-code, iterm2, docker-desktop, 1password
  Git        Ada Lovelace · ada@example.com
  SSH        new key for GitHub (you'll choose a passphrase)
  Node.js    lts/lithium, lts/krypton (default lts/lithium) · pnpm, typescript
  macOS      Dock: auto-hide on, Key repeat rate 2, Finder: hidden files on, …
  Updates    weekly, Monday 09:00
  GitHub     sign in with the GitHub CLI (optional, at the end)

  Continue? [Y/n]

[4/8] Homebrew
  ✓ ripgrep                      4s
  · jq                           already installed
  ✓ visual-studio-code           21s

────────────────────────────────────────────────
✓ Done in 14m 05s
  31 changed · 6 already set

  Next
  ➜ Open a new terminal (or run: exec $SHELL -l) to start using everything

  Full log: ~/Library/Logs/zapz/setup-20261109-091500.log
  Backups of edited files: ~/.local/state/zapz/backups/20261109-091500
```

## 📖 Usage

```text
Usage: zapz [OPTIONS]

Options:
    -n, --dry-run          Show what would happen, change nothing
    -y, --yes              Don't ask for confirmation
    --configure            Answer a few questions to (re)create your config
    -c, --config FILE      Use custom config file
    -g, --gist URL         Use settings from a GitHub Gist raw URL
    --skip-macos           Skip macOS preferences setup
    --skip-schedule        Skip scheduled update setup (alias: --skip-cron)
    --update               Update zapz to the latest version
    -v, --verbose          Enable verbose output
    --version              Show version information
    -h, --help             Show this help message
```

Examples:

```bash
zapz --dry-run                        # Preview only
zapz --configure                      # Re-run the setup wizard
zapz -c ~/dotfiles/zapz.yml           # Use a config kept elsewhere
zapz --skip-macos --skip-schedule     # Packages and tools only
zapz --yes                            # Unattended (e.g. scripts, CI)
```

zapz exits with status 1 if any item failed, so scripts can tell.

## ⚙️ Configuration

The setup wizard writes `~/.local/share/zapz/config/default.yml` from one of
the [presets](config/presets/) and your answers. Edit it any time, or re-run
`zapz --configure`, which asks before replacing it and backs up the old one.
Updates never overwrite it. Anything you leave out or leave empty is skipped.
Every option is documented in
[`config/default.yml.example`](config/default.yml.example).

```yaml
git:
  user:
    name: "Your Name"
    email: "you@example.com"
  editor: "code --wait"
  default_branch: "main"
  config:                      # any other git config --global options
    pull.rebase: "true"

node:
  versions: ["lts/lithium", "lts/krypton"]
  default: "lts/lithium"
  global_packages: ["pnpm", "typescript"]

homebrew:
  taps: []
  formulas: ["gh", "jq", "ripgrep", "oven-sh/bun/bun"]
  casks: ["visual-studio-code", "iterm2"]

macos:
  dock: { autohide: true, magnification: false }
  keyboard: { key_repeat: 2, initial_key_repeat: 15 }
  finder: { show_hidden_files: true, show_path_bar: true }
  developer_mode: false        # DevToolsSecurity; asks for your password

cron:
  update_schedule:
    enabled: true
    frequency: "weekly"        # daily, weekly or monthly
    time: "09:00"
    days: ["Monday"]
```

See the [configuration reference](https://corbanb.github.io/zapz/configuration)
for every option.

### Sharing a config with a Gist

Put your config in a [GitHub Gist](https://gist.github.com), click **Raw**, and
pass that URL:

```bash
zapz --gist https://gist.githubusercontent.com/you/abc123/raw/zapz.yml
```

Only `https` URLs are accepted.

## 🔄 Staying up to date

**zapz itself.** When a new release is out, new terminals show a one-line
notice. The check runs in the background at most once a day, so it never slows
your prompt. Update with:

```bash
zapz --update
```

To turn the notice off, add `export ZAPZ_DISABLE_UPDATE_CHECK=1` to your shell
config.

**Your packages.** With `cron.update_schedule.enabled`, zapz installs a launchd
agent that updates Homebrew packages, global npm packages and App Store apps (if
[`mas`](https://github.com/mas-cli/mas) is installed) on your schedule. Unlike
cron, launchd catches up on runs missed while the Mac was asleep. Output goes
to `~/Library/Logs/zapz/update.log`. To stop it, set `enabled: false` and run
`zapz` again.

## 🔍 Troubleshooting

**`zapz: command not found`.** Open a new terminal, or run `exec $SHELL -l`.

**Something failed.** The summary lists each problem, and the full output is
in the log it names (`~/Library/Logs/zapz/`). Fix the cause and run `zapz`
again; everything that already worked is skipped.

**A Homebrew app failed.** Usually it was already installed by hand. Delete
the app from `/Applications` and re-run, or remove it from your config.

**Undo a change to a shell or SSH file.** zapz copies each file to
`~/.local/state/zapz/backups/<date-time>/` before editing it. Its own changes
are between `# >>> zapz … >>>` and `# <<< zapz … <<<` lines, so you can also
just delete that block.

**Running without a terminal (scripts, CI).** Pass `--yes`, and make sure the
account can use `sudo` without a password if Homebrew or apps need installing.

## 🛠 Development

```bash
git clone https://github.com/corbanb/zapz.git && cd zapz
brew install yq shellcheck yamllint
./test/run_tests.sh
```

The tests run every setup module against a throwaway `HOME` with stubbed
system commands, so they're safe to run on your own Mac (and on Linux). See
[CONTRIBUTING.md](CONTRIBUTING.md).

## 📝 License

[MIT](LICENSE)
