---
layout: docs
title: Examples
icon: fas fa-code
description: Complete configs for common setups, and the commands to run them
---

Each example is a config file plus the command that uses it. Save the config
over `~/.local/share/zapz/config/default.yml`, or keep it anywhere and pass it
with `-c`. See [Configuration]({{ site.baseurl }}/configuration/) for what
every key does.

- [Node.js Setup]({{ site.baseurl }}/docs/examples/node/): Node versions, global
  npm packages and the tools around them
- [Team Configuration]({{ site.baseurl }}/docs/examples/team/): one config in a
  gist that everyone runs

## Basic setup

```bash
# Install zapz
curl -fsSL https://raw.githubusercontent.com/corbanb/zapz/main/install.sh | bash

# Open a new terminal, review the config, then run with default settings
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

With no `node` section, zapz still installs nvm but no Node versions. With no
`cron` section, scheduled updates stay off.

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
zapz -c ~/dotfiles/zapz.yml
```
