---
layout: docs
title: Configuration
icon: fas fa-cog
description: Every setting zapz reads from your config file
permalink: /configuration/
---

## Configuration file

zapz reads its settings from:

```text
~/.local/share/zapz/config/default.yml
```

You don't have to write it by hand. On first install, the setup wizard asks
your name and email, what you'll use the Mac for, a few follow-up picks, your
terminal and shell, and whether you want macOS settings and scheduled
updates, then writes this file (see
[The setup wizard]({{ site.baseurl }}/docs/#the-setup-wizard)). Run the wizard
again any time with:

```bash
zapz --configure
```

When the wizard replaces an existing config, the previous version is backed up
to `~/.local/state/zapz/backups/<date-time>/` first. Without a terminal (for
example in CI), the installer copies `config/default.yml.example` instead.

Edit the file freely, then run `zapz --dry-run` to see what would change, or
`zapz` to preview and apply it. `zapz --update` never overwrites it. To use a
different file for one run, pass `-c FILE` or `-g URL` (see the
[CLI reference]({{ site.baseurl }}/cli/)).

## What the wizard writes

The wizard starts from
[`catalog/base.yml`](https://github.com/corbanb/zapz/blob/main/catalog/base.yml)
and adds your answers:

- `git.user.name` and `git.user.email` from the first screen.
- `profile.chosen`: the titles of the personas and extras you picked.
- Every item from the essentials and from each persona and extra you picked,
  plus the follow-up picks you made: Homebrew formulas and casks go to
  `homebrew.formulas` and `homebrew.casks`, mise tools to `languages.tools`,
  App Store apps to `apps.app_store`, and guided downloads, commands and
  sign-in reminders to `checklist`. Lists are merged and duplicates removed.
  [Personas and Extras]({{ site.baseurl }}/docs/personas/) lists every item.
- `terminal.app` from the terminal question. Ghostty, iTerm2 and Warp are
  also added to `homebrew.casks`.
- `shell.setup` from the shell question. Recommended adds `starship`,
  `zsh-autosuggestions` and `zsh-syntax-highlighting` to
  `homebrew.formulas`; Light adds `starship`.
- `git.editor`: the first editor you're getting, in this order: VS Code
  (`code --wait`), Cursor (`cursor --wait`), Zed (`zed --wait`). Not set if
  you picked none of them.
- If you answer no to macOS settings it removes the `macos` section, and if
  you answer no to automatic updates it sets
  `cron.update_schedule.enabled: false`.

From `base.yml` you also get: `main` as the default branch,
`pull.rebase: "true"`, Ghostty with JetBrainsMono Nerd Font, the
Recommended shell, all three security settings on, the Dock, keyboard,
Finder and screenshot settings shown below, and weekly updates on Mondays at
09:00.

**Missing or empty values are skipped.** Delete any key or section you don't
want zapz to manage. For example, an empty `git.user.name` keeps your existing
git identity, and leaving out `macos.dock.autohide` leaves that Dock setting
alone. The same goes for `security`: each setting runs only when it's `true`
(the setup wizard turns all three on).

The config has these sections: `profile`, `git`, `homebrew`, `languages`,
`apps`, `terminal`, `shell`, `security`, `macos`, `cron` and `checklist`.
Older configs may also have `node`, which still works. zapz ignores any other
keys.

## Full example

This is `config/default.yml.example` as shipped. It lists every option:

```yaml
# What the wizard set this config up for (shown in the preview)
profile:
  chosen: ["Software development", "Voice dictation"]

# Git
git:
  user:
    name: ""   # Leave empty to keep your existing git identity
    email: ""
  editor: "code --wait"
  default_branch: "main"
  # Any other `git config --global` options
  config:
    core.autocrlf: "input"
    pull.rebase: "true"

# Homebrew packages (formulas) and apps (casks)
homebrew:
  taps: []            # Third-party taps; zapz also trusts them (brew trust)
  formulas:
    - "git"
    - "gh"
    - "jq"
    - "ripgrep"
    - "mise"
  casks:
    - "visual-studio-code"
    - "ghostty"
    - "1password"

# Languages and runtimes, installed with mise (https://mise.jdx.dev)
languages:
  tools:
    - "node@lts"
    - "python@3.13"
    - "bun@latest"

# Mac App Store apps (installed with mas; you need to be signed in, and to
# have bought paid apps). Anything that can't install becomes a checklist item.
apps:
  app_store:
    - {name: "Final Cut Pro", id: 424389933}

# Your terminal: ghostty (zapz sets the font), iterm2, warp, or terminal
terminal:
  app: "ghostty"
  font: "JetBrainsMono Nerd Font"

# Your shell: recommended (Oh My Zsh, autosuggestions, highlighting,
# Starship prompt), light (Starship only), or none (leave it alone)
shell:
  setup: "recommended"

# Safer defaults
security:
  touch_id_sudo: true     # Use Touch ID for sudo
  firewall: true          # Turn on the macOS firewall
  filevault_check: true   # Remind you to turn on FileVault if it's off

# macOS settings (omit a key to leave that setting alone)
macos:
  dock:
    autohide: true
    magnification: false
    minimize-to-application: true
  keyboard:
    key_repeat: 2            # Lower is faster
    initial_key_repeat: 15   # Lower is a shorter delay
  finder:
    show_all_extensions: true
    show_hidden_files: true
    show_path_bar: true
    show_status_bar: true
  screenshots:
    folder: "~/Pictures/Screenshots"
  developer_mode: false      # Enable DevToolsSecurity (asks for your password)

# Scheduled updates (Homebrew, mise languages, App Store via mas)
cron:
  update_schedule:
    enabled: true
    frequency: "weekly"   # daily, weekly or monthly (monthly runs on the 1st)
    time: "09:00"         # 24-hour HH:MM
    days: ["Monday"]      # Weekly only; one or more day names

# Things only you can do, shown at the end with links to open or commands
# to run (the wizard adds downloads and sign-ins here)
checklist:
  - title: "Download DaVinci Resolve"
    url: "https://www.blackmagicdesign.com/products/davinciresolve"
  - title: "Sign in to 1Password"
  - title: "Set up Paperclip"
    command: "npx paperclipai@latest onboard --yes"

# Older configs: Node.js with nvm (use languages.tools with mise instead)
node:
  versions: []
  default: ""
  global_packages: []
```

## profile

| Key | Type | Effect |
| --- | --- | --- |
| `profile.chosen` | list of strings | The personas and extras the wizard set this config up for, e.g. `["Software development", "Voice dictation"]`. Shown as the "For" row of the preview. It doesn't change what gets installed; the lists below do. |

## git

| Key | Type | Effect |
| --- | --- | --- |
| `git.user.name` | string | Sets `git config --global user.name`. If empty and you have no name set, zapz asks for it before setup starts (or, with no terminal, adds it to the checklist at the end). |
| `git.user.email` | string | Sets `git config --global user.email`. Also used as the comment on a new SSH key. If empty and you have no email set, zapz asks for it the same way. |
| `git.editor` | string | Sets `core.editor`, e.g. `"vim"` or `"code --wait"`. The GitHub CLI's editor is set to match. |
| `git.default_branch` | string | Sets `init.defaultBranch`. |
| `git.config` | map | Any other `git config --global` options, as `key: "value"` pairs, e.g. `pull.rebase: "true"`. |

zapz also adds these defaults, but only where you haven't set them already:
the aliases `co`, `br`, `ci`, `st`, `unstage` and `last`, and
`color.ui auto`.

## homebrew

zapz installs Homebrew if it's missing. Packages that are already installed are
left alone. If a tap, formula or cask fails (usually because
the app was installed outside Homebrew), zapz carries on and lists the failures
in the summary at the end.

| Key | Type | Effect |
| --- | --- | --- |
| `homebrew.taps` | list of strings | Added with `brew tap` and, on Homebrew 6 or later, trusted with `brew trust`, so formulas and casks from them load. Listing a tap here is the decision to trust it. e.g. `"hashicorp/tap"`. You don't need a tap for a fully qualified name like `oven-sh/bun/bun`. |
| `homebrew.formulas` | list of strings | Installed with `brew install`. Tap-qualified names work and tap automatically, e.g. `"oven-sh/bun/bun"`. |
| `homebrew.casks` | list of strings | Installed with `brew install --cask`. |

Some other sections need a formula here to work: `mise` for
`languages.tools`, `mas` for `apps.app_store`, and `starship` (plus
`zsh-autosuggestions` and `zsh-syntax-highlighting` for `recommended`) for
`shell.setup`. The wizard adds them for you. The preview shows friendly names
for packages it knows from the catalog, e.g. "VS Code" for
`visual-studio-code`.

## languages

Languages and runtimes are installed with [mise](https://mise.jdx.dev), one
tool for Node.js, Python, Bun, Go, Rust and more, with per-project versions.
If `languages.tools` is empty or missing, the step is skipped.

| Key | Type | Effect |
| --- | --- | --- |
| `languages.tools` | list of strings | mise tool specs, each installed with `mise use --global`, e.g. `"node@lts"`, `"python@3.13"`, `"bun@latest"`, `"npm:eas-cli"`. Tools mise already has are skipped. |

This step needs the `mise` formula in `homebrew.formulas`; without it, it's
reported as failed. zapz adds a block that runs `mise activate` to `~/.zshrc`
(or `~/.bash_profile` if your shell is bash), so new shells use these
versions. Scheduled updates run `mise upgrade`.

## apps

| Key | Type | Effect |
| --- | --- | --- |
| `apps.app_store` | list of `{name, id}` | Mac App Store apps, installed with [mas](https://github.com/mas-cli/mas), e.g. `{name: "Final Cut Pro", id: 424389933}`. `id` is the number in the app's App Store URL; `name` is what zapz shows. |

You need to be signed in to the App Store, and to have bought paid apps. An
app that can't install isn't counted as a failure: it's shown as skipped and
added to the checklist at the end, with a link that opens its App Store page.
Apps already installed are skipped. The step needs the `mas` formula in
`homebrew.formulas`, and is left out of the run when the list is empty.

## terminal

| Key | Type | Effect |
| --- | --- | --- |
| `terminal.app` | string | `ghostty`, `iterm2`, `warp` or `terminal` (Apple's Terminal). Missing or empty: the terminal is left alone. |
| `terminal.font` | string | The font to use. Default: `"JetBrainsMono Nerd Font"` (the essentials install it as `font-jetbrains-mono-nerd-font`). |

For `ghostty`, zapz writes a marked block to `~/.config/ghostty/config` that
sets the font, size 14, some window padding and a bar cursor. For the others,
it adds a checklist item to set the font yourself, so icons show up.

`terminal.app` doesn't install the app: list its cask (`ghostty`, `iterm2` or
`warp`) in `homebrew.casks`. The wizard does this for you.

## shell

| Key | Type | Effect |
| --- | --- | --- |
| `shell.setup` | string | `recommended`, `light` or `none`. Missing means `none`. |

- **`recommended`**: installs [Oh My Zsh](https://ohmyz.sh) in `~/.oh-my-zsh`
  if it's missing, then turns on zsh-autosuggestions, zsh-syntax-highlighting,
  fzf key bindings, zoxide, `ls`/`ll` aliases using eza, and the
  [Starship](https://starship.rs) prompt.
- **`light`**: the Starship prompt only.
- **`none`**: leaves your shell alone. If an earlier run added zapz's shell
  block, it's removed (the file is backed up first).

Everything goes in one marked block (`# >>> zapz shell >>>`) in `~/.zshrc`, so
it's easy to remove. If your shell is bash, the block goes in
`~/.bash_profile` and Oh My Zsh and the zsh plugins are left out.

## security

Safer defaults. Each setting runs only when it's `true`; the setup wizard
turns all three on. A config without a `security` section (for example one
written by an older zapz) never changes these settings.

| Key | Type | Effect |
| --- | --- | --- |
| `security.touch_id_sudo` | boolean | Use Touch ID for `sudo`. zapz adds `auth sufficient pam_tid.so` to `/etc/pam.d/sudo_local`, which survives macOS updates. Needs your password. |
| `security.firewall` | boolean | Turn on the macOS application firewall. Needs your password. |
| `security.filevault_check` | boolean | Check FileVault disk encryption. zapz never turns FileVault on itself, because macOS shows a recovery key you must save. If it's off, zapz adds a checklist item that opens the FileVault settings. |

Settings that are already on are reported as already set. `false` or missing
leaves the setting as it is; it doesn't turn anything off.

## macos

Each setting is written with `defaults write`, unless macOS already has that
value. Leave a key out to leave that setting alone. A Dock, keyboard or Finder
value of the wrong type is shown as skipped and ignored.
If anything changed, zapz then restarts the Dock, Finder and SystemUIServer.
Skip this whole section for one run with `--skip-macos`.

| Key | Type | macOS setting |
| --- | --- | --- |
| `macos.dock.autohide` | boolean | Automatically hide and show the Dock. |
| `macos.dock.magnification` | boolean | Magnify Dock icons on hover. |
| `macos.dock.minimize-to-application` | boolean | Minimize windows into their app's icon. |
| `macos.keyboard.key_repeat` | integer | Key repeat rate (`KeyRepeat`). Lower is faster. |
| `macos.keyboard.initial_key_repeat` | integer | Delay before repeat starts (`InitialKeyRepeat`). Lower is shorter. |
| `macos.finder.show_all_extensions` | boolean | Show all filename extensions. |
| `macos.finder.show_hidden_files` | boolean | Show hidden files in Finder. |
| `macos.finder.show_path_bar` | boolean | Show the path bar in Finder. |
| `macos.finder.show_status_bar` | boolean | Show the status bar in Finder. |
| `macos.screenshots.folder` | string | Save screenshots to this folder instead of the Desktop, e.g. `"~/Pictures/Screenshots"`. `~` is your home folder; zapz creates the folder if needed. |
| `macos.developer_mode` | boolean | When `true`, runs `sudo DevToolsSecurity -enable` so debuggers can attach without a password prompt each time. It asks for your password. `false` or missing does nothing (it does not turn Developer Mode off). |

## cron

`cron.update_schedule` controls a launchd agent that keeps your packages up to
date. The section is called `cron` for historical reasons, but zapz uses launchd,
which catches up on runs missed while the Mac was asleep. Skip this step for one
run with `--skip-schedule`.

| Key | Type | Default | Effect |
| --- | --- | --- | --- |
| `cron.update_schedule.enabled` | boolean | `false` | When `true`, installs or refreshes the agent. When `false` or missing, removes an agent zapz installed earlier. |
| `cron.update_schedule.frequency` | string | `daily` | `daily`, `weekly` or `monthly`. Monthly runs on the 1st. |
| `cron.update_schedule.time` | string | `09:00` | 24-hour `HH:MM`. |
| `cron.update_schedule.days` | list of strings | none | Weekly only. One or more day names, e.g. `["Monday", "Thursday"]`. Required when `frequency` is `weekly`. |

The defaults apply when a key is missing; the wizard writes `enabled: true`,
`weekly`, `09:00` and `["Monday"]`. An invalid frequency, time or day name
stops zapz with an error.

Each scheduled run:

- runs `brew update`, `brew upgrade` and `brew cleanup`
- runs `mise upgrade` if mise is installed
- runs `npm update -g` with nvm's default Node, if nvm is installed (older
  configs)
- runs `mas upgrade` if [mas](https://github.com/mas-cli/mas) is installed and your account can use `sudo` without a password (mas needs administrator rights; otherwise macOS keeps App Store apps updated)
- shows a macOS notification when it finishes or if something fails

The agent is saved at
`~/Library/LaunchAgents/com.github.corbanb.zapz.update.plist`, and output goes
to `~/Library/Logs/zapz/update.log`.

To change the schedule or turn it off, edit this section and run `zapz` again.

## checklist

Things only you can do, such as downloads that need a sign-up, sign-ins and
commands to run yourself. The preview lists them under "You'll need to:", and
the end of the run shows them as a numbered "Things only you can do" list.
If any have a link, zapz offers to open them all.

| Key | Type | Effect |
| --- | --- | --- |
| `checklist[].title` | string | What to do, e.g. `"Sign in to 1Password"`. Required. |
| `checklist[].url` | string | Optional link to open, e.g. a download page. |
| `checklist[].command` | string | Optional command, shown under the item for you to copy and run. zapz doesn't run it. |
| `checklist[].note` | string | Optional note. The wizard copies the catalog's note here (e.g. "free; Blackmagic asks you to register"); shown under the item at the end. |

The wizard fills this list from your picks: guided downloads (title
"Download …" with the page's URL), commands such as Paperclip or Xcode, and
sign-in reminders. zapz adds its own items during the run too, for example to
turn on FileVault, to get an App Store app that couldn't install, or to add
your SSH key to GitHub.

## node (older configs)

Configs written before mise support set Node.js up with
[nvm](https://github.com/nvm-sh/nvm). These keys still work, but new configs
should use [`languages.tools`](#languages) (e.g. `"node@lts"`) instead. If
`node.versions` is empty or missing, the step is left out of the run and nvm
isn't installed.

| Key | Type | Effect |
| --- | --- | --- |
| `node.versions` | list of strings | Versions to install with `nvm install`. Any version nvm accepts works: `"lts/krypton"`, `"22"`, `"20.11.1"`. Versions that are already installed are skipped. |
| `node.default` | string | Set as nvm's `default` alias, so new shells use it. |
| `node.global_packages` | list of strings | Installed with `npm install -g` if not already installed. A package that fails is listed in the summary and zapz carries on. |

zapz installs nvm if needed and adds a block that loads it to `~/.zshrc` (or
`~/.bash_profile` if your shell is bash).
