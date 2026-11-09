---
layout: docs
title: Examples
icon: fas fa-code
description: Complete configs for common setups, and the commands to run them
---

Each example is a config file plus the command that uses it. Save the config
over `~/.local/share/zapz/config/default.yml`, or keep it anywhere and pass it
with `-c`. Run `zapz --dry-run` first to see what it would change. See
[Configuration]({{ site.baseurl }}/configuration/) for what every key does.

You can also start from one of the presets the setup wizard uses and trim it:
[`essentials.yml`](https://github.com/corbanb/zapz/blob/main/config/presets/essentials.yml),
[`webdev.yml`](https://github.com/corbanb/zapz/blob/main/config/presets/webdev.yml)
or [`minimal.yml`](https://github.com/corbanb/zapz/blob/main/config/presets/minimal.yml).
See [Presets]({{ site.baseurl }}/configuration/#presets) for what each one
installs, or run `zapz --configure` to pick one again.

- [Node.js Setup]({{ site.baseurl }}/docs/examples/node/): Node versions, global
  npm packages and the tools around them
- [Team Configuration]({{ site.baseurl }}/docs/examples/team/): one config in a
  gist that everyone runs

## Basic setup

```bash
# Install zapz: it asks a few questions, writes your config, and offers to
# preview and run setup right away
curl -fsSL https://raw.githubusercontent.com/corbanb/zapz/main/install.sh | bash

# Later, in a new terminal: preview, confirm, then run
zapz
```

## Minimal config

Anything you leave out is skipped, so a config can be as small as you like.
This one sets your git identity and installs a few packages, and nothing else:

```yaml
git:
  user:
    name: "Your Name"
    email: "you@example.com"
  default_branch: "main"

homebrew:
  formulas:
    - "gh"
    - "jq"
    - "ripgrep"
  casks:
    - "visual-studio-code"
```

With no `node` section, the Node.js step is skipped and nvm isn't installed.
With no `cron` section, scheduled updates stay off. With no `macos` section,
your Dock, keyboard and Finder settings are left alone.

## Packages only

On a machine where you don't want zapz to change system settings or add a
background job, skip those steps:

```bash
zapz --skip-macos --skip-schedule
```

## Config in a dotfiles repo

Keep your config under version control and point zapz at it:

```bash
git clone git@github.com:you/dotfiles.git ~/dotfiles
zapz --dry-run -c ~/dotfiles/zapz.yml   # see what it would change
zapz -c ~/dotfiles/zapz.yml
```
