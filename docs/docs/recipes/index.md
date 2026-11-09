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

### Start over from a preset

Run the setup wizard again and pick Essentials, Web development or Minimal:

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

### Pin Node versions

```yaml
node:
  versions: ["22.11.0", "20.18.0"]
  default: "22.11.0"
```

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

### Enable Developer Mode

```yaml
macos:
  developer_mode: true
```

zapz asks for your password once, before setup starts, to run
`DevToolsSecurity -enable`.

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
