<div align="center">

# ⚡️ zapz

**Set up a new Mac for the way you work, and see everything before it happens.**

[![Version](https://img.shields.io/github/v/release/corbanb/zapz?include_prereleases&label=version)](https://github.com/corbanb/zapz/releases)
[![CI](https://github.com/corbanb/zapz/actions/workflows/ci.yml/badge.svg)](https://github.com/corbanb/zapz/actions/workflows/ci.yml)
[![Catalog check](https://github.com/corbanb/zapz/actions/workflows/catalog.yml/badge.svg)](https://github.com/corbanb/zapz/actions/workflows/catalog.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![macOS](https://img.shields.io/badge/macOS-14%2B-brightgreen)](#requirements)

[🚀 Quick start](#-quick-start) · [✨ What you get](#-what-you-get) · [🔒 What it changes](#-what-zapz-changes-and-what-it-never-does) · [↩️ Undo](#%EF%B8%8F-undo-and-uninstall) · [📖 Docs](https://corbanb.github.io/zapz)

</div>

---

Tell zapz what you do (developer, AI builder, video editor, creator, designer
and more) and it installs the apps and tools for that, sets up git, an SSH
key, your terminal and shell, sensible macOS and security settings, and keeps
everything up to date.

- **No YAML to start.** A short wizard asks who you are and what you'll use
  the Mac for, with recommendations marked, and writes the config for you.
- **Nothing happens without a preview.** You see every app, tool and setting
  zapz will install or change, what you already have, and what will need you,
  then say yes. `zapz --dry-run` shows the same preview any time.
- **Questions first, then hands-off.** Your password, git identity and SSH
  passphrase are asked up front; the long part runs without you.
- **Honest about what it can't do.** App Store purchases, downloads behind a
  sign-up and app sign-ins end up on a "Things only you can do" checklist with
  links.
- **Safe to run again, easy to undo.** What's already there is left alone,
  files are backed up before they're edited, and everything zapz adds is
  clearly marked.

## 🚀 Quick start

```bash
curl -fsSL https://raw.githubusercontent.com/corbanb/zapz/main/install.sh | bash
```

Prefer to read it first? It's about 150 lines:

```bash
curl -fsSLO https://raw.githubusercontent.com/corbanb/zapz/main/install.sh
less install.sh
bash install.sh
```

The installer puts zapz in `~/.local/share/zapz`, asks a few questions, shows
you the plan and asks before setting anything up. On a brand-new Mac it first
opens Apple's Command Line Tools dialog; click **Install** and it carries on.

### Requirements

- macOS 14 (Sonoma) or later; 15 or later recommended (what Homebrew fully
  supports). Tested on macOS 15, 26 and 27.
- An administrator account. zapz asks for your password once, at the start.
- For App Store apps: sign in to the App Store, and buy paid apps there first.

## ✨ What you get

Pick any combination of personas. Everyone gets the **essentials**: git and
the GitHub CLI, modern command-line tools (ripgrep, fzf, bat, eza, zoxide…),
1Password, The Unarchiver, AppCleaner, a browser of your choice and a Nerd
Font.

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

**Your terminal and shell:** Ghostty ★, iTerm2, Warp or Apple's Terminal, and
Oh My Zsh with autosuggestions, syntax highlighting and the Starship prompt
(or just Starship, or leave your shell alone).

Every app comes from [`catalog/`](catalog/); see the
[full list with every option](https://corbanb.github.io/zapz/docs/personas/).
A [weekly check](.github/workflows/catalog.yml) confirms each one is still
available in Homebrew, so you're never offered a retired app.

### What a run looks like

```text
  ⚡ zapz 0.3.0 · macOS 27.2 · Apple Silicon

  Here's what zapz will do:

  For        Software development, Video editing, Voice dictation
  Tools      Command Line Tools: already installed
  Security   turn on Touch ID for sudo, turn on the firewall, check FileVault
  Homebrew   install Homebrew
  Packages   git, GitHub CLI, jq, ripgrep, fd, fzf, bat, eza, zoxide, mise, uv, ffmpeg…
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
  ✓ cursor                       18s
  · git                          already installed

────────────────────────────────────────────────
✓ Your Mac is ready ⚡  24m 12s
  58 changed · 6 already set

  Things only you can do
   1  Sign in to 1Password
   2  Download DaVinci Resolve
      free; Blackmagic asks you to register
      open: https://www.blackmagicdesign.com/products/davinciresolve
   3  Turn on FileVault (and save the recovery key somewhere safe)
      open: x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?FileVault

  Open the 2 link(s) now? [Y/n]
```

## 🔒 What zapz changes, and what it never does

### Where things go

| What | Where | Notes |
|---|---|---|
| zapz itself, your config, its `yq` | `~/.local/share/zapz/` | `yq` is a pinned download, checked against its SHA-256 |
| The `zapz` command | `~/.local/bin/zapz` | A link to `setup.sh` |
| Shell setup | `~/.zshrc`, `~/.zprofile` (or `~/.bash_profile`) | Only between `# >>> zapz … >>>` and `# <<< zapz … <<<` lines |
| Apps and tools | Homebrew (`/opt/homebrew`), `/Applications` | Installed with Homebrew; nothing you have is removed |
| Languages | `~/.local/share/mise`, `~/.config/mise` | Through mise |
| Git settings | `~/.gitconfig` | Your existing name and email are kept unless your config sets them |
| SSH key | `~/.ssh/id_ed25519`, `~/.ssh/config` | Only created if you don't have a key; a GitHub entry is added to your config |
| Terminal and shell | `~/.config/ghostty/config`, `~/.oh-my-zsh` | Ghostty settings are in a marked block too |
| Touch ID for sudo | `/etc/pam.d/sudo_local` | One line, added with your password |
| Firewall, macOS settings | System settings (`defaults`) | Only the settings shown in the preview |
| Scheduled updates | `~/Library/LaunchAgents/com.github.corbanb.zapz.update.plist` | Runs `brew upgrade` and `mise upgrade` |
| Logs | `~/Library/Logs/zapz/` | Every run and every scheduled update |
| Backups | `~/.local/state/zapz/backups/<date-time>/` | Copies of files before zapz edits them |

### What zapz never does

- **No tracking.** zapz has no analytics, telemetry or accounts.
- **Nothing without asking.** Every change is in the preview, and nothing
  happens until you say yes (or pass `--yes`).
- **Nothing removed.** zapz doesn't uninstall apps, delete your files, or
  overwrite settings it wasn't asked to manage. Turning an option off removes
  only zapz's own block or launch agent.
- **No FileVault surprises.** zapz never turns on FileVault for you (macOS
  shows a recovery key you must save); it reminds you instead.
- **No purchases or sign-ins.** App Store purchases, licenses and account
  sign-ins stay with you, on the checklist.
- **No commands you didn't see.** Commands on the checklist, like Paperclip's
  setup, are shown for you to run; zapz doesn't run them.
- **Admin rights only where needed.** Your password is used for installing
  Homebrew and apps, App Store installs, Touch ID for sudo, the firewall and
  Developer Mode, and nothing else.

### What it connects to

GitHub (zapz itself, the `yq` download, Oh My Zsh, and a once-a-day check for
new zapz releases), Homebrew and the download sites of the apps you choose,
mise's language downloads, and the App Store through `mas`. Nothing else.

## ↩️ Undo and uninstall

Restore any edited file from `~/.local/state/zapz/backups/`, or delete the
marked `# >>> zapz … >>>` blocks yourself. To remove zapz completely:

```bash
# Stop scheduled updates
launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.github.corbanb.zapz.update.plist
rm -f ~/Library/LaunchAgents/com.github.corbanb.zapz.update.plist

# Remove zapz itself
rm -rf ~/.local/share/zapz ~/.local/bin/zapz ~/.cache/zapz ~/.local/state/zapz

# Then delete the "# >>> zapz … >>>" blocks from ~/.zshrc, ~/.zprofile
# (or ~/.bash_profile) and ~/.config/ghostty/config
```

Apps and tools zapz installed stay installed; remove any you don't want with
`brew uninstall <name>` or AppCleaner. To turn off Touch ID for sudo, delete
the `pam_tid.so` line from `/etc/pam.d/sudo_local` (with `sudo`).

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

```bash
zapz --dry-run                        # Preview only
zapz --configure                      # Re-run the setup wizard
zapz -c ~/dotfiles/zapz.yml           # Use a config kept elsewhere
zapz --skip-macos --skip-schedule     # Apps and tools only
zapz --yes                            # Unattended (e.g. scripts, CI)
```

zapz exits with status 1 if any item failed, so scripts can tell. To install
a specific release or branch, set `ZAPZ_REF` when installing (for example
`ZAPZ_REF=v0.3.0` or `ZAPZ_REF=main`).

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
  formulas: ["gh", "jq", "ripgrep", "mise", "mas"]
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
pass that URL. Preview it first:

```bash
zapz --gist https://gist.githubusercontent.com/you/abc123/raw/zapz.yml --dry-run
```

Only `https` URLs are accepted.

## 🔄 Staying up to date

**zapz itself.** When a new release is out, new terminals show a one-line
notice. The check runs in the background at most once a day, so it never slows
your prompt. Update with `zapz --update`; it never moves to an older version.
To turn the notice off, add `export ZAPZ_DISABLE_UPDATE_CHECK=1` to your shell
config.

**Your apps and tools.** With `cron.update_schedule.enabled`, a launchd agent
runs `brew upgrade` and `mise upgrade` on your schedule (App Store apps too,
if your account can use `sudo` without a password; otherwise macOS keeps them
updated). Unlike cron, launchd catches up on runs missed while the Mac was
asleep. Output goes to `~/Library/Logs/zapz/update.log`. To stop it, set
`enabled: false` and run `zapz` again.

## ✅ How it's tested

- More than 90 automated tests run every setup step against a throwaway home folder,
  including running each step twice to catch duplicated changes.
- CI runs them on macOS 15, 26 and 27 (under the macOS `/bin/bash`) and on
  Linux, with ShellCheck and yamllint.
- A weekly job checks every app in the catalog against Homebrew.
- Downloads that zapz makes itself are pinned to a version, and `yq` is
  verified against its checksum.

## 🔍 Troubleshooting

**`zapz: command not found`.** Open a new terminal, or run `exec $SHELL -l`.

**Something failed.** The summary lists each problem, and the full output is
in the log it names (`~/Library/Logs/zapz/`). Fix the cause and run `zapz`
again; everything that already worked is skipped.

**A Homebrew app failed.** Usually it was installed by hand under another
name. Delete the app from `/Applications` and re-run, or remove it from your
config.

**Running without a terminal (scripts, CI).** Pass `--yes`, and make sure the
account can use `sudo` without a password if Homebrew or apps need installing.

## 🛠 Development

```bash
git clone https://github.com/corbanb/zapz.git && cd zapz
brew install yq shellcheck yamllint
./test/run_tests.sh
```

The tests use a throwaway `HOME` and stand-in system commands, so they're safe
to run on your own Mac (and on Linux). See [CONTRIBUTING.md](CONTRIBUTING.md).

## 📝 License

[MIT](LICENSE). Contributions welcome.
