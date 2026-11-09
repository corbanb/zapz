---
layout: docs
title: Documentation
icon: fas fa-book
description: Install zapz and set up your Mac from a single YAML file
permalink: /docs/
---

## Requirements

- macOS 14 (Sonoma) or later; 15 or later recommended (what Homebrew fully supports)
- An administrator account (Homebrew and apps need your password once)

On a new Mac, the installer first opens Apple's Command Line Tools dialog
(which provides git); click **Install** and it continues once that finishes.

zapz installs everything else it needs, including Homebrew. It reads your
config with [yq](https://github.com/mikefarah/yq), which it downloads (a
pinned, checksum-verified copy) into `~/.local/share/zapz/bin`; you don't need
to install it.

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/corbanb/zapz/main/install.sh | bash
```

The installer:

1. installs the latest zapz release to `~/.local/share/zapz` (set `ZAPZ_HOME`
   to install somewhere else) and links the `zapz` command into
   `~/.local/bin`. It adds a marked block to `~/.zshrc` (or `~/.bash_profile`
   if your shell is bash) that puts `~/.local/bin` on your `PATH` and shows
   update notices;
2. runs the setup wizard, which asks a few questions and writes your config
   (see [below](#the-setup-wizard));
3. offers to preview and run setup right away: `Preview and run setup now?`.

If `~/.local/share/zapz/config/default.yml` already exists, the installer keeps
it and skips the wizard. With no terminal to ask (for example in CI, or with
`ZAPZ_NONINTERACTIVE` set), it copies `config/default.yml.example` instead.

Prefer to read the installer first? Download it, look, then run it:

```bash
curl -fsSLO https://raw.githubusercontent.com/corbanb/zapz/main/install.sh
less install.sh
bash install.sh
```

To install a specific release or branch, set `ZAPZ_REF`. If the project has no
releases yet, the installer uses the default branch.

```bash
curl -fsSL https://raw.githubusercontent.com/corbanb/zapz/main/install.sh | ZAPZ_REF=v0.2.0 bash
```

Running the installer again updates an existing install and keeps your config.

## The setup wizard

The wizard asks:

- your name and email, for git commits (your current `git config` values are
  offered as defaults);
- what to install, as a preset: **Essentials** (command-line tools, VS Code,
  iTerm2), **Web development** (Essentials plus Node.js, Bun, Deno, Docker
  Desktop and 1Password; the default) or **Minimal** (command-line tools only);
- whether to apply recommended macOS settings (Dock, Finder, key repeat);
- whether to keep your apps and tools updated automatically (Mondays at 09:00).

It writes the answers to `~/.local/share/zapz/config/default.yml`. Edit that
file any time, or run the wizard again with `zapz --configure`. See
[Configuration]({{ site.baseurl }}/configuration/) for every setting.

## Usage

If you didn't run setup from the installer, open a new terminal and run:

```bash
zapz
```

zapz shows what it will install and change, and what you already have, then
asks `Continue? [Y/n]`. To see the preview without changing anything:

```bash
zapz --dry-run
```

### What to expect

- **Questions first.** Before the long part starts, zapz asks for anything it
  needs: your git name and email if they aren't set anywhere, and your Mac
  password once (for Homebrew, apps and Developer Mode). The SSH key
  passphrase is asked when the key is created, early in the run.
- **Then hands-off.** Homebrew, apps and Node.js install without you. Each item
  gets one line: `✓` changed, `·` already set, `-` skipped, `✗` failed. A
  package that fails doesn't stop the rest.
- **GitHub at the end.** If the GitHub CLI is installed and you aren't signed
  in, zapz offers to sign in through your browser, which can upload your new
  SSH key.
- **A summary and a notification.** The summary counts what changed and what
  was already set, lists any problems and next steps, and names the log file.
  Long runs end with a macOS notification, so you can walk away.

### Logs and backups

- Each run's full output goes to `~/Library/Logs/zapz/setup-<date-time>.log`.
- Before zapz edits a shell startup file or `~/.ssh/config`, or the wizard
  replaces your config, it copies the file to
  `~/.local/state/zapz/backups/<date-time>/`.
- zapz's own changes to shell files are between `# >>> zapz … >>>` and
  `# <<< zapz … <<<` lines, so you can also just delete that block.

### Basic Commands

```bash
# Show help
zapz --help

# Preview, confirm, then run
zapz

# Preview only
zapz --dry-run

# Re-run the setup wizard
zapz --configure

# Run with a custom config
zapz -c path/to/config.yml

# Run with a config from a gist
zapz -g https://gist.githubusercontent.com/you/abc123/raw/zapz.yml

# Skip macOS preferences and scheduled updates
zapz --skip-macos --skip-schedule

# Don't ask for confirmation (scripts, CI)
zapz --yes
```

Running `zapz` again is safe: anything already installed or configured is
reported as already set and left alone. zapz exits with status 1 if anything
failed. See the [CLI reference]({{ site.baseurl }}/cli/) for every option and
the [configuration reference]({{ site.baseurl }}/configuration/) for every
setting.

## Staying up to date

When a newer release of zapz is out, new terminals show a one-line notice. The
check runs in the background at most once a day. Update with:

```bash
zapz --update
```

To turn the notice off, add this to your shell config:

```bash
export ZAPZ_DISABLE_UPDATE_CHECK=1
```

Your packages are kept up to date separately by the scheduled updates in the
`cron` section of your config. See
[Configuration]({{ site.baseurl }}/configuration/#cron).

## More

- [Examples]({{ site.baseurl }}/docs/examples/): complete configs for common setups
- [Recipes]({{ site.baseurl }}/docs/recipes/): short answers to common tasks
- [README on GitHub](https://github.com/corbanb/zapz/blob/main/README.md)
