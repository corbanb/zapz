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

`zapz` gets a new Mac ready for the way you work. Tell it what you do
(developer, AI builder, video editor, creator, designer and more) and it
installs the apps and tools for that, sets up git, an SSH key, your terminal
and shell, sensible macOS and security settings, and keeps everything up to
date.

It's built to be calm and trustworthy:

- **No YAML to start.** A short wizard asks who you are and what you'll use
  the Mac for, offers a few choices with recommendations marked, and writes
  the config for you.
- **See it before it happens.** zapz shows exactly what it will install and
  change, what you already have, and what will need you, then asks before
  touching anything. Try `zapz --dry-run` any time.
- **Questions first, then hands-off.** Your password, git identity and SSH
  passphrase are asked up front; the long part runs without you, and you get
  a notification when it's done.
- **Honest about what it can't do.** App Store purchases, downloads behind a
  sign-up and app sign-ins end up on a "Things only you can do" checklist,
  with links to open.
- **Safe to run again.** Anything already installed or set is left alone, and
  shell and SSH files are backed up before zapz edits them.

## ✨ Who it's for

Pick any combination; everyone also gets the **essentials**: git and the
GitHub CLI, modern command-line tools (ripgrep, fzf, bat, eza, zoxide…),
1Password, a browser of your choice, and a Nerd Font.

| Persona | Includes (★ = recommended choices) |
|---|---|
| Software development | VS Code, OrbStack ★, Node.js, Bun, pnpm and Python via mise, uv; Cursor ★, Bruno ★, Zed, JetBrains, TablePlus… |
| AI building | Claude, Claude Code, ChatGPT, Cursor, JupyterLab; Conductor ★, T3 Code, Paperclip, Codex, Antigravity CLI, OpenCode… |
| Mobile apps | Xcode (via Xcodes), Android Studio, CocoaPods, fastlane; Flutter, Expo |
| Game development | Unity Hub, Godot; Unreal (Epic Games), Blockbench, Tiled, Aseprite, Blender |
| Data science | Positron, JupyterLab, DuckDB, DBeaver, Python; Quarto ★, R, RStudio, Tableau |
| Video editing | HandBrake, IINA, ffmpeg; choose DaVinci Resolve, Final Cut Pro, Premiere Pro or Edits |
| Content & streaming | OBS, Descript, CapCut, Canva, Shottr, Kap; Edits ★, Premiere, Elgato, Loopback… |
| Design | Figma, Affinity, ImageOptim, FontBase; Framer, Spline, Pixelmator Pro |
| Team collaboration | Slack, Zoom, Notion, Notion Calendar, Obsidian; Discord |

**Extras anyone can add:** meeting notes (Granola ★, Krisp, or open-source
Meetily and Anarlog), voice dictation (Wispr Flow ★, Superwhisper, Aqua Voice,
MacWhisper, or open-source VoiceInk, Handy, OpenWhispr, Buzz), local AI models
(Ollama, LM Studio) and Raycast.

The full lists live in [`catalog/`](catalog/), and a weekly check makes sure
every app is still available in Homebrew.

## 🧭 What setup does

1. **Command Line Tools** (Apple's developer tools, which include git)
2. **Security**: Touch ID for `sudo`, the firewall on, and a FileVault check
3. **Git**: name, email, editor, default branch and other `git config` options
4. **SSH key**: an ed25519 key protected by a passphrase that macOS keeps in
   your Keychain, plus a `github.com` entry in `~/.ssh/config`
5. **Homebrew** and your apps and tools. Anything that fails is listed in the
   summary instead of stopping setup.
6. **Languages** with [mise](https://mise.jdx.dev): Node.js, Python, Bun, Go…
7. **Terminal & shell**: Ghostty ★ (or iTerm2, Warp, Terminal) with the right
   font, and Oh My Zsh with suggestions, highlighting and the Starship prompt
8. **App Store** apps you picked (when you're signed in and own them)
9. **macOS settings**: Dock, key repeat, Finder and a Screenshots folder
10. **Scheduled updates**: a launchd job that runs `brew upgrade`,
    `mise upgrade` and `mas upgrade` on your schedule
11. **GitHub**: sign in with the GitHub CLI, which can upload your SSH key

Steps that don't apply to your choices are skipped.

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
  ⚡ zapz 0.3.0 · macOS 27.2 · Apple Silicon

  Here's what zapz will do:

  For        Software development, Video editing, Voice dictation
  Tools      Command Line Tools: already installed
  Security   turn on Touch ID for sudo, turn on the firewall, check FileVault
  Homebrew   install Homebrew
  Apps       1Password, Chrome, VS Code, OrbStack, Cursor, HandBrake, Wispr Flow, Ghostty
  Git        Ada Lovelace · ada@example.com
  SSH        new key for GitHub (you'll choose a passphrase)
  Languages  node@lts, bun@latest, pnpm@latest, python@3.13 (with mise)
  Terminal   Ghostty · Oh My Zsh, suggestions, highlighting, Starship prompt
  App Store  Final Cut Pro (needs App Store sign-in)

  You'll need to:
    · sign in to the App Store
    · Download DaVinci Resolve
    · Sign in to Wispr Flow

  About 25 minutes. Only missing things are installed; files are backed up before edits.

  Continue? [Y/n]

[5/11] Homebrew
  ✓ Cursor                       18s
  · git                          already installed

────────────────────────────────────────────────
✓ Your Mac is ready ⚡  24m 12s
  58 changed · 6 already set

  Things only you can do
   1  Sign in to 1Password
   2  Download DaVinci Resolve
   3  Sign in to Wispr Flow
   4  Turn on FileVault (and save the recovery key somewhere safe)

  Open the 2 link(s) now? [Y/n]
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

The setup wizard writes `~/.local/share/zapz/config/default.yml` from the
[catalog](catalog/) and your answers. Edit it any time, or re-run
`zapz --configure`, which asks before replacing it and backs up the old one.
Updates never overwrite it. Anything you leave out or leave empty is skipped.
Every option is documented in
[`config/default.yml.example`](config/default.yml.example).

```yaml
git:
  user: { name: "Your Name", email: "you@example.com" }
  editor: "code --wait"

homebrew:
  formulas: ["gh", "jq", "ripgrep", "mise"]
  casks: ["visual-studio-code", "ghostty", "figma"]

languages:
  tools: ["node@lts", "python@3.13"]   # installed with mise

apps:
  app_store:
    - { name: "Final Cut Pro", id: 424389933 }

terminal: { app: "ghostty" }           # ghostty, iterm2, warp or terminal
shell: { setup: "recommended" }        # recommended, light or none

security: { touch_id_sudo: true, firewall: true, filevault_check: true }

macos:
  dock: { autohide: true }
  screenshots: { folder: "~/Pictures/Screenshots" }

checklist:                             # shown at the end, with links
  - { title: "Download DaVinci Resolve", url: "https://www.blackmagicdesign.com/products/davinciresolve" }
```

To add an app to a persona for everyone, edit its file in
[`catalog/`](catalog/README.md).

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

**Your apps and tools.** With `cron.update_schedule.enabled`, zapz installs a
launchd agent that updates Homebrew packages, mise languages and App Store apps
(if [`mas`](https://github.com/mas-cli/mas) is installed) on your schedule. Unlike
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
