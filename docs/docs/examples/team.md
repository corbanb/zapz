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

If it helps, run `zapz --configure` with the personas your team uses (for
example Software development and Team collaboration; see
[Personas and Extras]({{ site.baseurl }}/docs/personas/)) and trim the config it
writes. Leave `git.user` out so zapz keeps each person's own git identity:

```yaml
git:
  default_branch: "main"
  config:
    pull.rebase: "true"
    push.autoSetupRemote: "true"

homebrew:
  taps: []
  formulas:
    - "git"
    - "gh"
    - "jq"
    - "awscli"
    - "terraform"
    - "mise"
  casks:
    - "visual-studio-code"
    - "docker-desktop"
    - "slack"

languages:
  tools:
    - "node@22"
    - "pnpm@latest"

cron:
  update_schedule:
    enabled: true
    frequency: "weekly"
    time: "09:00"
    days: ["Monday"]
```

There is no `macos` section, so zapz leaves everyone's Dock, keyboard and
Finder settings alone, and no `terminal` or `shell` section, so it leaves
their terminal and shell alone too. With no `security` section, Touch ID for
`sudo`, the firewall and the FileVault check are on; add a `security` section
with `false` values if your team manages those another way.

Things people have to do themselves, such as signing in to a company tool,
can go in a `checklist`. zapz shows them at the end of setup:

```yaml
checklist:
  - title: "Sign in to Slack"
  - title: "Request access to the AWS console"
    url: "https://example.com/aws-access"
```

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
