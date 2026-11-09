---
layout: docs
title: Team Configuration
icon: fas fa-users
description: Share configurations across your team
permalink: /docs/examples/team/
---

Put one config in a GitHub Gist and have everyone run zapz with its raw URL.
New teammates get the same tools with one command.

## 1. Write the team config

Start from a preset if it helps (see
[Presets]({{ site.baseurl }}/configuration/#presets)). Leave `git.user` out so
zapz keeps each person's own git identity:

```yaml
git:
  default_branch: "main"
  config:
    pull.rebase: "true"
    push.autoSetupRemote: "true"

node:
  versions:
    - "lts/jod"
  default: "lts/jod"
  global_packages:
    - "pnpm"

homebrew:
  taps: []
  formulas:
    - "git"
    - "gh"
    - "jq"
    - "awscli"
    - "terraform"
  casks:
    - "visual-studio-code"
    - "docker-desktop"
    - "slack"

cron:
  update_schedule:
    enabled: true
    frequency: "weekly"
    time: "09:00"
    days: ["Monday"]
```

There is no `macos` section, so zapz leaves everyone's Dock, keyboard and
Finder settings alone.

## 2. Publish it as a gist

Create a gist at [gist.github.com](https://gist.github.com) with the config as
`zapz.yml`, open it, and click **Raw**. Copy that URL. It looks like:

```text
https://gist.githubusercontent.com/your-team/abc123/raw/zapz.yml
```

A raw URL without a commit hash always serves the latest revision of the gist.
One with a commit hash (`.../raw/<hash>/zapz.yml`) serves that revision only,
which is useful if you want to pin it.

## 3. Onboard a teammate

```bash
# Install zapz (on a new Mac this first installs the Command Line Tools).
# Answer the wizard's questions, then answer n to "Preview and run setup now?"
# so the team config is used instead of the personal one.
curl -fsSL https://raw.githubusercontent.com/corbanb/zapz/main/install.sh | bash

# Open a new terminal, then preview the team config
zapz --dry-run --gist https://gist.githubusercontent.com/your-team/abc123/raw/zapz.yml

# Apply it
zapz --gist https://gist.githubusercontent.com/your-team/abc123/raw/zapz.yml
```

The team config has no `git.user`, so zapz asks each person for their name and
email before setup starts, unless git already has them.

The URL must use `https`. zapz downloads it without credentials, so any `https`
URL that returns the YAML file works, such as a raw file in a public repository.

## Updating the team config

Edit the gist, then have people run the same `zapz --gist ...` command again.
The preview shows what's new before anything changes, and anything already
installed is reported as already set, so only the new packages are added.
zapz doesn't uninstall packages you remove from the list.
