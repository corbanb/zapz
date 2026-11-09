---
layout: docs
title: Recipe Collection
icon: fas fa-book-open
description: Short answers to common tasks
---

Each recipe is a config snippet or a command. Config snippets go in
`~/.local/share/zapz/config/default.yml` (or whatever file you pass with `-c`);
run `zapz --dry-run` to see what would change, then `zapz` to apply them. For
complete configs, see [Examples]({{ site.baseurl }}/docs/examples/).

## Config

### Start over with different personas

Run the setup wizard again and pick what you'll use the Mac for (see
[Personas and Extras]({{ site.baseurl }}/docs/personas/)):

```bash
zapz --configure
```

Your previous config is backed up to `~/.local/state/zapz/backups/<date-time>/`.

### See what zapz would do

```bash
zapz --dry-run
```

Nothing is changed. Combine it with `-c` or `--gist` to check a config before
applying it.

## Git

### Keep my existing git identity

Leave the name and email empty, or delete them:

```yaml
git:
  user:
    name: ""
    email: ""
```

### Use VS Code as the git editor

```yaml
git:
  editor: "code --wait"
```

### Set any other git option

```yaml
git:
  config:
    pull.rebase: "true"
    push.autoSetupRemote: "true"
    core.autocrlf: "input"
```

## Packages

### Install from a third-party tap

List the tap, then the formula:

```yaml
homebrew:
  taps:
    - "hashicorp/tap"
  formulas:
    - "hashicorp/tap/terraform"
```

A tap-qualified formula name such as `oven-sh/bun/bun` also works on its own.

### Add apps

```yaml
homebrew:
  casks:
    - "visual-studio-code"
    - "iterm2"
    - "docker-desktop"
```

If a cask fails because the app was already installed by hand, zapz lists it in
the summary and carries on. Delete the app from `/Applications` and run `zapz`
again, or remove it from your config.

### Add an App Store app

```yaml
apps:
  app_store:
    - {name: "Final Cut Pro", id: 424389933}
```

The `id` is the number at the end of the app's App Store URL. Sign in to the
App Store first, and buy paid apps; anything that can't install is added to
the checklist at the end with a link to its page. Needs `mas` in
`homebrew.formulas` (the essentials include it).

### Add an app to a persona (`catalog/`)

To change what the setup wizard offers, rather than your own config, edit the
persona's file in
[`catalog/`](https://github.com/corbanb/zapz/tree/main/catalog), e.g.
`catalog/personas/developer.yml`. Add the item under `core` (always
installed) or under one of the `picks` questions:

```yaml
      - kind: cask
        name: warp
        label: Warp
        note: AI built into the terminal
```

[`catalog/README.md`](https://github.com/corbanb/zapz/blob/main/catalog/README.md)
describes the file format and every item kind (Homebrew, mise, App Store,
guided download, command). Every Homebrew name is checked weekly in CI by
`scripts/check-catalog.sh`; run it yourself before opening a pull request.

## Languages

### Install a language or tool with mise

```yaml
homebrew:
  formulas:
    - "mise"

languages:
  tools:
    - "node@lts"
    - "python@3.13"
    - "go@latest"
```

Pin an exact version with, e.g., `"node@22.11.0"`. Scheduled updates run
`mise upgrade`.

### Pin Node versions with nvm (older configs)

Configs written before mise support use `node`, which still works:

```yaml
node:
  versions: ["22.11.0", "20.18.0"]
  default: "22.11.0"
```

New configs should use `languages.tools` instead.

## Terminal and shell

### Use iTerm2 instead of Ghostty

```yaml
homebrew:
  casks:
    - "iterm2"

terminal:
  app: "iterm2"
```

zapz only sets the font for Ghostty. For iTerm2, Warp or Terminal it adds a
checklist item to set the font to `terminal.font` yourself.

### Leave my shell alone

```yaml
shell:
  setup: "none"
```

If an earlier run added zapz's shell block, the next run removes it (and backs
the file up first). Use `"light"` for just the Starship prompt.

## macOS

### Faster key repeat

```yaml
macos:
  keyboard:
    key_repeat: 2
    initial_key_repeat: 15
```

Lower numbers mean faster repeat and a shorter delay before it starts.

### Leave macOS settings alone

For one run:

```bash
zapz --skip-macos
```

For good, delete the `macos` section from your config.

### Save screenshots to a folder

```yaml
macos:
  screenshots:
    folder: "~/Pictures/Screenshots"
```

### Enable Developer Mode

```yaml
macos:
  developer_mode: true
```

zapz asks for your password once, before setup starts, to run
`DevToolsSecurity -enable`.

## Security

### Turn the security settings on or off

The setup wizard turns all three on. To choose for yourself:

```yaml
security:
  touch_id_sudo: true      # Touch ID for sudo
  firewall: true           # macOS firewall on
  filevault_check: false   # skip the FileVault reminder
```

`false` or a missing key leaves that setting as it is; it doesn't turn
anything off. Without a `security` section, zapz doesn't touch any of them.

## Things only you can do

### Add your own checklist item

```yaml
checklist:
  - title: "Download DaVinci Resolve"
    url: "https://www.blackmagicdesign.com/products/davinciresolve"
  - title: "Set up Paperclip"
    command: "npx paperclipai@latest onboard --yes"
```

zapz lists these in the preview and again at the end of the run, and offers
to open the links. It never runs the commands for you.

## Scheduled updates

### Update every day

```yaml
cron:
  update_schedule:
    enabled: true
    frequency: "daily"
    time: "08:30"
```

### Update twice a week

```yaml
cron:
  update_schedule:
    enabled: true
    frequency: "weekly"
    time: "09:00"
    days: ["Monday", "Thursday"]
```

### Turn scheduled updates off

Set `enabled: false` and run `zapz` again. zapz removes the launchd agent.

```yaml
cron:
  update_schedule:
    enabled: false
```

### See what the last update did

```bash
tail -n 50 ~/Library/Logs/zapz/update.log
```

### Run the update now

```bash
bash ~/.local/share/zapz/lib/maintenance.sh
```

## zapz itself

### Update zapz

```bash
zapz --update
```

### Install a specific release

```bash
curl -fsSL https://raw.githubusercontent.com/corbanb/zapz/main/install.sh | ZAPZ_REF=v0.2.0 bash
```

By default the installer uses the latest release. `ZAPZ_REF=main` installs the
latest code from the main branch instead.

### Read the installer before running it

```bash
curl -fsSLO https://raw.githubusercontent.com/corbanb/zapz/main/install.sh
less install.sh
bash install.sh
```

### Install somewhere else

```bash
curl -fsSL https://raw.githubusercontent.com/corbanb/zapz/main/install.sh | ZAPZ_HOME="$HOME/tools/zapz" bash
```

### Turn off the update notice

```bash
export ZAPZ_DISABLE_UPDATE_CHECK=1
```

Add it to `~/.zshrc` to make it permanent.

### Run without prompts (scripts, CI)

```bash
zapz --yes
```

Without a terminal, zapz won't start unless you pass `--yes`. The account must
be able to use `sudo` without a password if Homebrew or apps need installing.

### Find the log of the last run

```bash
ls -t ~/Library/Logs/zapz/setup-*.log | head -n 1
```

The summary at the end of each run also prints the log's path.

### Undo a change to a shell or SSH file

zapz copies each file to `~/.local/state/zapz/backups/<date-time>/` before
editing it. Its own changes are between `# >>> zapz … >>>` and
`# <<< zapz … <<<` lines, so you can also just delete that block.

### `zapz: command not found`

Open a new terminal, or run `exec $SHELL -l`.
