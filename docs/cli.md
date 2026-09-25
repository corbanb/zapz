---
layout: default
title: CLI Reference
permalink: /cli/
---

# CLI Reference

zapz is a single command. It has no subcommands: running `zapz` runs the whole
setup, and the options below change where the config comes from or skip
optional steps.

```text
Usage: zapz [OPTIONS]

Set up a macOS development environment from a YAML config.

Options:
    -h, --help             Show this help message
    -v, --verbose          Enable verbose output
    --version              Show version information
    --update               Update zapz to the latest version
    -c, --config FILE      Use custom config file
    -g, --gist URL         Use settings from a GitHub Gist raw URL
    --skip-macos           Skip macOS preferences setup
    --skip-schedule        Skip scheduled update setup (alias: --skip-cron)
```

## Options

| Option | Description |
| --- | --- |
| *(none)* | Run the full setup using `~/.local/share/zapz/config/default.yml`. If that file is missing, it is created from `config/default.yml.example` first. |
| `-h`, `--help` | Print usage and exit. |
| `-v`, `--verbose` | Print debug messages too, such as each package that is already installed or being installed. |
| `--version` | Print the installed version and the project URL, then exit. |
| `--update` | Update zapz itself with `git pull --ff-only` in the install directory, then exit. Fails if local changes in the install directory block a fast-forward. Your `config/default.yml` is not tracked by git, so updates never touch it. |
| `-c`, `--config FILE` | Use `FILE` instead of the default config. zapz exits with an error if the file doesn't exist. |
| `-g`, `--gist URL` | Download the config from `URL` and use it for this run. The URL must use `https`. Use the gist's **Raw** URL, for example `https://gist.githubusercontent.com/USER/ID/raw/config.yml`. The download goes to a private temp file that is deleted when zapz exits. If you pass both `-c` and `-g`, the gist is used. |
| `--skip-macos` | Skip the macOS preferences step (Dock, keyboard, Finder, Developer Mode). |
| `--skip-schedule` | Skip the scheduled updates step. `--skip-cron` is an alias. |

`--help`, `--version` and `--update` exit as soon as they are read, so they
don't run the setup. An unknown option, or `-c`/`-g` without a value, prints
an error and the usage text and exits with status 1.

## What a run does

Steps run in this order. Each one skips work that is already done, so running
`zapz` again is safe.

1. **Xcode Command Line Tools.** Opens the installer dialog if they're missing
   and waits for it to finish.
2. **Homebrew.** Installs Homebrew if needed, adds its `shellenv` to
   `~/.zprofile`, installs `yq`, runs `brew update`, then installs your taps,
   formulas and casks. If a package fails, zapz carries on and lists the failed
   packages at the end of the step.
3. **Git.** Applies your `git` settings and adds a few aliases (`co`, `br`,
   `ci`, `st`, `unstage`, `last`) and `color.ui auto`, but only where you
   haven't set those already.
4. **SSH and GitHub.** Creates an ed25519 key at `~/.ssh/id_ed25519` if you
   don't have one. It asks for a passphrase and stores it in your Keychain.
   Adds a `github.com` entry to `~/.ssh/config`, signs in to the GitHub CLI
   (`gh auth login` in the browser) if `gh` is installed, and copies your public
   key to the clipboard.
5. **Node.js.** Installs nvm if needed, then your Node versions, your default
   version and your global npm packages.
6. **macOS preferences.** Writes the settings from your `macos` section, then
   restarts the Dock, Finder and SystemUIServer. Skipped with `--skip-macos`.
7. **Scheduled updates.** Installs or removes a launchd agent that keeps
   packages updated. Skipped with `--skip-schedule`.

zapz only runs on macOS 12 (Monterey) or later.

See [Configuration]({{ site.baseurl }}/configuration/) for what each setting
does.

## Examples

```bash
# Run with the default config
zapz

# See every step
zapz --verbose

# Use a config kept elsewhere, e.g. in a dotfiles repo
zapz -c ~/dotfiles/zapz.yml

# Use a shared config from a gist
zapz --gist https://gist.githubusercontent.com/you/abc123/raw/zapz.yml

# Packages and tools only: leave macOS settings and scheduled updates alone
zapz --skip-macos --skip-schedule

# Update zapz itself
zapz --update
```

## Environment variables

| Variable | Used by | Description |
| --- | --- | --- |
| `ZAPZ_HOME` | installer | Install location. Default: `~/.local/share/zapz`. |
| `ZAPZ_REF` | installer | Branch or tag to install, e.g. `v0.2.0`. Default: the repository's default branch. |
| `ZAPZ_DISABLE_UPDATE_CHECK` | shell | Set to any value to turn off the "new version available" notice in new terminals. |

```bash
# Install a specific release
curl -fsSL https://raw.githubusercontent.com/corbanb/zapz/main/install.sh | ZAPZ_REF=v0.2.0 bash

# Turn off the update notice (add to ~/.zshrc)
export ZAPZ_DISABLE_UPDATE_CHECK=1
```
