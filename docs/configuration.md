---
layout: docs
title: Configuration
icon: fas fa-cog
description: Every setting zapz reads from your config file
permalink: /configuration/
---

## Configuration file

The installer copies `config/default.yml.example` to:

```text
~/.local/share/zapz/config/default.yml
```

Edit that file, then run `zapz`. `zapz --update` never overwrites it. To use a
different file for one run, pass `-c FILE` or `-g URL` (see the
[CLI reference]({{ site.baseurl }}/cli/)).

**Missing or empty values are skipped.** Delete any key or section you don't
want zapz to manage. For example, an empty `git.user.name` keeps your existing
git identity, and leaving out `macos.dock.autohide` leaves that Dock setting
alone.

The config has five sections: `git`, `node`, `homebrew`, `macos` and `cron`.
zapz ignores any other keys.

## Full example

This is `config/default.yml.example` as shipped:

```yaml
git:
  user:
    name: ""   # Leave empty to keep your existing git identity
    email: ""
  editor: "vim"
  default_branch: "main"
  config:
    core.autocrlf: "input"
    pull.rebase: "true"

node:
  versions:
    - "lts/krypton"   # Node.js 24
    - "lts/jod"       # Node.js 22
  default: "lts/krypton"
  global_packages:
    - "pnpm"
    - "typescript"

homebrew:
  taps: []
  formulas:
    - "git"
    - "gh"
    - "jq"
    - "ripgrep"
    - "fd"
    - "tree"
    - "wget"
    - "oven-sh/bun/bun"
    - "deno"
  casks:
    - "visual-studio-code"
    - "iterm2"
    - "docker"
    - "1password"

macos:
  dock:
    autohide: true
    magnification: false
    minimize-to-application: true
  keyboard:
    key_repeat: 2
    initial_key_repeat: 15
  finder:
    show_all_extensions: true
    show_hidden_files: true
    show_path_bar: true
    show_status_bar: true
  developer_mode: false

cron:
  update_schedule:
    enabled: true
    frequency: "weekly"
    time: "09:00"
    days: ["Monday"]
```

## git

| Key | Type | Effect |
| --- | --- | --- |
| `git.user.name` | string | Sets `git config --global user.name`. If empty and you have no name set, zapz prints a warning. |
| `git.user.email` | string | Sets `git config --global user.email`. Also used as the comment on a new SSH key. If empty and you have no email set, zapz prints a warning. |
| `git.editor` | string | Sets `core.editor`, e.g. `"vim"` or `"code --wait"`. The GitHub CLI's editor is set to match. |
| `git.default_branch` | string | Sets `init.defaultBranch`. |
| `git.config` | map | Any other `git config --global` options, as `key: "value"` pairs, e.g. `pull.rebase: "true"`. |

zapz also adds these defaults, but only where you haven't set them already:
the aliases `co`, `br`, `ci`, `st`, `unstage` and `last`, and
`color.ui auto`.

## node

Node.js is installed with [nvm](https://github.com/nvm-sh/nvm). zapz installs
nvm if needed and adds a block that loads it to `~/.zshrc` and `~/.bashrc`.

| Key | Type | Effect |
| --- | --- | --- |
| `node.versions` | list of strings | Versions to install with `nvm install`. Any version nvm accepts works: `"lts/krypton"`, `"22"`, `"20.11.1"`. Versions that are already installed are skipped. |
| `node.default` | string | Set as nvm's `default` alias, so new shells use it. |
| `node.global_packages` | list of strings | Installed with `npm install -g` if not already installed. A package that fails prints a warning and zapz carries on. |

## homebrew

zapz installs Homebrew if it's missing. Packages that are already installed are
skipped. If a tap, formula or cask fails (usually because the app was installed
outside Homebrew), zapz carries on and lists the failures at the end of the
step.

| Key | Type | Effect |
| --- | --- | --- |
| `homebrew.taps` | list of strings | Added with `brew tap`, e.g. `"hashicorp/tap"`. |
| `homebrew.formulas` | list of strings | Installed with `brew install`. Tap-qualified names work and tap automatically, e.g. `"oven-sh/bun/bun"`. |
| `homebrew.casks` | list of strings | Installed with `brew install --cask`. |

Bun and Deno are ordinary formulas in the example (`oven-sh/bun/bun` and
`deno`). Remove them if you don't want them.

## macos

Each setting is written with `defaults write`. Leave a key out to leave that
setting alone. A Dock, keyboard or Finder value of the wrong type prints a
warning and is ignored.
Afterwards zapz restarts the Dock, Finder and SystemUIServer. Skip this whole
section for one run with `--skip-macos`.

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

An invalid frequency, time or day name stops zapz with an error.

Each scheduled run:

- runs `brew update`, `brew upgrade` and `brew cleanup`
- runs `npm update -g` with nvm's default Node
- runs `mas upgrade` if [mas](https://github.com/mas-cli/mas) is installed
- shows a macOS notification when it finishes or if something fails

The agent is saved at
`~/Library/LaunchAgents/com.github.corbanb.zapz.update.plist`, and output goes
to `~/Library/Logs/zapz/update.log`.

To change the schedule or turn it off, edit this section and run `zapz` again.
