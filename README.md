<div align="center">

# ⚡️ zapz

Set up a Mac for development with one command, from one YAML file.

[![Version](https://img.shields.io/github/v/release/corbanb/zapz?include_prereleases&label=version)](https://github.com/corbanb/zapz/releases)
[![CI](https://github.com/corbanb/zapz/actions/workflows/ci.yml/badge.svg)](https://github.com/corbanb/zapz/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![macOS](https://img.shields.io/badge/macOS-12%2B-brightgreen)](#requirements)

[📖 Documentation](https://corbanb.github.io/zapz) | [🚀 Quick Start](#-quick-start) | [⚙️ Configuration](#%EF%B8%8F-configuration)

</div>

---

## 🎯 Overview

`zapz` turns a fresh Mac into a working development machine: Homebrew and your
packages, git, an SSH key for GitHub, Node.js, sensible macOS settings, and
scheduled updates. Everything it does comes from a YAML config you can keep in
a Gist and share with your team.

It's safe to run again. Each step checks what's already there, packages that
are already installed are skipped, and shell config changes are written once
inside marked blocks rather than appended every run.

## ✨ What it sets up

In order:

1. **Xcode Command Line Tools**
2. **Homebrew**, then your taps, formulas and casks. A package that fails to
   install is reported at the end instead of stopping the run.
3. **Git**: name, email, editor, default branch and any other `git config`
   options. Blank values leave your existing settings alone.
4. **SSH**: an ed25519 key (you choose a passphrase; macOS keeps it in your
   Keychain), a `github.com` entry in `~/.ssh/config`, and GitHub CLI login.
5. **Node.js** via [nvm](https://github.com/nvm-sh/nvm): the versions you list,
   a default, and global npm packages.
6. **macOS preferences**: Dock, keyboard repeat and Finder settings.
7. **Scheduled updates**: a launchd job that runs `brew upgrade`,
   `npm update -g` and `mas upgrade` daily, weekly or monthly.

The example config also installs Bun, Deno, VS Code, iTerm2, Docker and
1Password. Edit the lists to suit you.

## 🚀 Quick Start

### Requirements

- macOS 12 (Monterey) or later
- git, which comes with the Xcode Command Line Tools
  (`xcode-select --install`)

zapz installs everything else it needs, including Homebrew and
[yq](https://github.com/mikefarah/yq).

### Install

```bash
curl -fsSL https://raw.githubusercontent.com/corbanb/zapz/main/install.sh | bash
```

This clones zapz to `~/.local/share/zapz`, adds a `zapz` command to
`~/.local/bin`, creates your config at
`~/.local/share/zapz/config/default.yml`, and updates `~/.zshrc` (or
`~/.bash_profile` for bash) so the command is on your `PATH`.

To install a specific release or branch, set `ZAPZ_REF`:

```bash
curl -fsSL https://raw.githubusercontent.com/corbanb/zapz/main/install.sh | ZAPZ_REF=v0.2.0 bash
```

### Run

Review the config, open a new terminal, then:

```bash
zapz
```

Some steps are interactive: the Xcode installer dialog, your SSH key
passphrase, and GitHub CLI login in the browser.

## 📖 Usage

```text
Usage: zapz [OPTIONS]

Options:
    -h, --help             Show this help message
    -v, --verbose          Enable verbose output
    --version              Show version information
    --update               Update zapz to the latest version
    -c, --config FILE      Use custom config file
    -g, --gist URL         Use settings from a GitHub Gist raw URL
    --skip-macos           Skip macOS preferences setup
    --skip-schedule        Skip scheduled update setup (alias: --skip-cron)
```

Examples:

```bash
zapz --verbose                        # See every step
zapz -c ~/dotfiles/zapz.yml           # Use a config kept elsewhere
zapz --skip-macos --skip-schedule     # Packages and tools only
```

## ⚙️ Configuration

The installer copies [`config/default.yml.example`](config/default.yml.example)
to `~/.local/share/zapz/config/default.yml`. Edit that file; updates never
overwrite it. Anything you leave out or leave empty is skipped.

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
  versions: ["lts/krypton", "lts/jod"]
  default: "lts/krypton"
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

**`zapz: command not found`.** Open a new terminal, or run `source ~/.zshrc`.

**"An incompatible yq is still first on your PATH".** Another program called
`yq` (the Python one) is shadowing the one zapz needs. Remove it, or put
Homebrew's `bin` directory earlier in your `PATH`.

**A Homebrew cask failed.** Usually the app was already installed by hand.
zapz lists failed packages at the end and carries on; delete the app or remove
it from your config.

**See what happened.** Run `zapz --verbose`. Scheduled update output is in
`~/Library/Logs/zapz/update.log`.

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
