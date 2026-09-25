---
layout: docs
title: Documentation
icon: fas fa-book
description: Install zapz and set up your Mac from a single YAML file
permalink: /docs/
---

## Requirements

- macOS 12 (Monterey) or later
- git, which comes with the Xcode Command Line Tools:

  ```bash
  xcode-select --install
  ```

zapz installs everything else it needs, including Homebrew and
[yq](https://github.com/mikefarah/yq).

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/corbanb/zapz/main/install.sh | bash
```

The installer:

- clones zapz to `~/.local/share/zapz` (set `ZAPZ_HOME` to install somewhere else)
- links the `zapz` command into `~/.local/bin`
- copies `config/default.yml.example` to `~/.local/share/zapz/config/default.yml`,
  unless that file already exists
- adds a marked block to `~/.zshrc` (or `~/.bash_profile` if your shell is
  bash) that puts `~/.local/bin` on your `PATH` and shows update notices

To install a specific release or branch, set `ZAPZ_REF`:

```bash
curl -fsSL https://raw.githubusercontent.com/corbanb/zapz/main/install.sh | ZAPZ_REF=v0.2.0 bash
```

Running the installer again updates an existing install.

## Usage

Review `~/.local/share/zapz/config/default.yml`, open a new terminal, then run:

```bash
zapz
```

Some steps need you: the Xcode installer dialog, your SSH key passphrase, the
GitHub CLI login in your browser, and your password if you enable Developer
Mode.

### Basic Commands

```bash
# Show help
zapz --help

# Run with default settings
zapz

# Run with custom config
zapz -c path/to/config.yml

# Run with a config from a gist
zapz -g https://gist.githubusercontent.com/you/abc123/raw/zapz.yml

# Run with verbose output
zapz --verbose

# Skip macOS preferences and scheduled updates
zapz --skip-macos --skip-schedule
```

Running `zapz` again is safe: anything already installed or configured is
skipped. See the [CLI reference]({{ site.baseurl }}/cli/) for every option and
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
