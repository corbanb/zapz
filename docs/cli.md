---
layout: default
title: CLI Reference
permalink: /cli/
---

# CLI Reference

zapz is a single command. It has no subcommands: running `zapz` previews the
whole setup, asks before changing anything, then runs it. The options below
preview without changing anything, skip the confirmation, re-run the setup
wizard, change where the config comes from or skip optional steps.

```text
Usage: zapz [OPTIONS]

Set up a macOS development environment from a YAML config.

Options:
    -n, --dry-run          Show what would happen, change nothing
    -y, --yes              Don't ask for confirmation
    --configure            Answer a few questions to (re)create your config
    -c, --config FILE      Use custom config file
    -g, --gist URL         Use settings from a GitHub Gist raw URL
    --skip-macos           Skip macOS preferences setup
    --skip-schedule        Skip scheduled update setup (alias: --skip-cron)
    --update               Update zapz to the latest version
    -v, --verbose          Enable verbose output
    --version              Show version information
    -h, --help             Show this help message
```

## Options

| Option | Description |
| --- | --- |
| *(none)* | Preview and, once you confirm, run the full setup using `~/.local/share/zapz/config/default.yml`. If that file is missing, it is created from `config/default.yml.example` first. |
| `-n`, `--dry-run` | Show the preview ("Here's what zapz will do") and exit. Nothing on your Mac is changed. |
| `-y`, `--yes` | Don't ask "Continue?" after the preview. Required when there is no terminal to answer from (scripts, CI). |
| `--configure` | Run the setup wizard again: it asks your name, email, which preset to start from, and whether to apply macOS settings and scheduled updates, then rewrites `config/default.yml` and exits. The previous config is backed up first. Needs a terminal. |
| `-c`, `--config FILE` | Use `FILE` instead of the default config. zapz exits with an error if the file doesn't exist. |
| `-g`, `--gist URL` | Download the config from `URL` and use it for this run. The URL must use `https`. Use the gist's **Raw** URL, for example `https://gist.githubusercontent.com/USER/ID/raw/config.yml`. The download goes to a private temp file that is deleted when zapz exits. If you pass both `-c` and `-g`, the gist is used. |
| `--skip-macos` | Skip the macOS settings step (Dock, keyboard, Finder, Developer Mode). |
| `--skip-schedule` | Skip the scheduled updates step. `--skip-cron` is an alias. |
| `--update` | Update zapz itself, then exit. A branch install is updated with `git pull --ff-only`; a release install (the default) moves to the newest release tag. Fails if local changes in the install directory block the update. Your `config/default.yml` is not tracked by git, so updates never touch it. |
| `-v`, `--verbose` | Print debug messages too. Command output always goes to the log file. |
| `--version` | Print the installed version and the project URL, then exit. |
| `-h`, `--help` | Print usage and exit. |

`--help`, `--version`, `--update` and `--configure` act as soon as they are
read, so they don't run the setup. An unknown option, or `-c`/`-g` without a
value, prints an error and the usage text and exits with status 1.

## What a run does

1. **Banner and preview.** zapz prints its version, your macOS version and
   chip, then "Here's what zapz will do": what will be installed or changed,
   and what you already have. With `--dry-run` it stops here.
2. **Confirmation.** It asks `Continue? [Y/n]`. Answer `n` and nothing is
   changed. `--yes` skips the question; without a terminal, zapz exits with an
   error unless you pass `--yes`.
3. **Questions up front.** If neither your config nor git has your name or
   email, zapz asks for them now. If Homebrew, apps or Developer Mode need it,
   it asks for your password once and keeps `sudo` fresh for the rest of the
   run, so the long part doesn't stop to ask again.
4. **Steps.** They run in this order. Each one compares your config with what
   is already on the Mac, so anything already installed or set is reported as
   "already set" and left alone, and running `zapz` again is safe.
   1. **Command Line Tools.** Opens Apple's installer dialog if they're missing
      and waits for it to finish.
   2. **Git.** Applies your `git` settings and adds a few aliases (`co`, `br`,
      `ci`, `st`, `unstage`, `last`) and `color.ui auto`, but only where you
      haven't set those already.
   3. **SSH key.** Creates an ed25519 key at `~/.ssh/id_ed25519` if you don't
      have one. It asks for a passphrase and stores it in your Keychain. Adds a
      `github.com` entry to `~/.ssh/config`.
   4. **Homebrew.** Installs Homebrew if needed, adds its `shellenv` to
      `~/.zprofile` (`~/.bash_profile` for bash), runs `brew update`, then
      installs your taps, formulas and casks. A package that fails is listed in
      the summary and setup carries on.
   5. **Node.js.** Installs nvm if needed, then your Node versions, your
      default version and your global npm packages. Skipped when
      `node.versions` is empty or missing.
   6. **macOS settings.** Writes the settings from your `macos` section, and
      restarts the Dock, Finder and SystemUIServer if anything changed.
      Skipped with `--skip-macos`.
   7. **Scheduled updates.** Installs or removes a launchd agent that keeps
      packages updated. Skipped with `--skip-schedule`.
   8. **GitHub.** If `gh` is installed and you're not signed in, offers to sign
      in with the GitHub CLI in your browser, which can upload your new SSH
      key. Otherwise the summary says how to add the key yourself.
5. **Summary.** How many items changed and how many were already set, any
   problems, next steps, the path of the full log and, if zapz edited any
   files, where it backed them up.
6. **Notification.** A macOS notification when a run that took more than a
   minute finishes, or when anything failed.

Each run writes a log to `~/Library/Logs/zapz/setup-<date-time>.log`. Before
zapz edits a shell startup file or `~/.ssh/config` (or the wizard replaces your
config), it copies the file to `~/.local/state/zapz/backups/<date-time>/`.

zapz only runs on macOS 14 (Sonoma) or later, and warns below macOS 15, which
is the oldest version Homebrew fully supports. It reads your config with
[yq](https://github.com/mikefarah/yq); if a compatible `yq` isn't already on
your `PATH`, zapz downloads a pinned, checksum-verified copy into
`~/.local/share/zapz/bin`. You don't need to install it.

See [Configuration]({{ site.baseurl }}/configuration/) for what each setting
does.

## Exit status

| Status | Meaning |
| --- | --- |
| `0` | Setup finished with no problems, a dry run finished, or you answered `n` at the confirmation. |
| `1` | Any item failed (listed under "Problems" in the summary), or zapz couldn't start: an unknown option, a missing config file, invalid YAML, an unsupported macOS version, or no terminal to confirm with and no `--yes`. |

## Examples

```bash
# Preview, confirm, then run with the default config
zapz

# Preview only; change nothing
zapz --dry-run

# Re-run the setup wizard to start from a different preset
zapz --configure

# Run without asking for confirmation (scripts, CI)
zapz --yes

# Use a config kept elsewhere, e.g. in a dotfiles repo
zapz -c ~/dotfiles/zapz.yml

# Preview a shared config from a gist before applying it
zapz --dry-run --gist https://gist.githubusercontent.com/you/abc123/raw/zapz.yml

# Packages and tools only: leave macOS settings and scheduled updates alone
zapz --skip-macos --skip-schedule

# Update zapz itself
zapz --update
```

## Environment variables

| Variable | Used by | Description |
| --- | --- | --- |
| `ZAPZ_HOME` | installer, shell | Install location. Default: `~/.local/share/zapz`. |
| `ZAPZ_REF` | installer | Branch or tag to install, e.g. `v0.2.0` or `main`. Default: the latest release, or the default branch if there are no releases yet. |
| `ZAPZ_DISABLE_UPDATE_CHECK` | shell | Set to any value to turn off the "new version available" notice in new terminals. |
| `ZAPZ_NONINTERACTIVE` | installer, `zapz` | Set to any value to never prompt. The installer copies `config/default.yml.example` instead of running the wizard, and `zapz` needs `--yes`. |
| `NO_COLOR` | `zapz` | Set to any value to turn off colors ([no-color.org](https://no-color.org)). Colors and the spinner are also off when output isn't a terminal. |

```bash
# Install a specific release
curl -fsSL https://raw.githubusercontent.com/corbanb/zapz/main/install.sh | ZAPZ_REF=v0.2.0 bash

# Install the latest code from the main branch instead of the latest release
curl -fsSL https://raw.githubusercontent.com/corbanb/zapz/main/install.sh | ZAPZ_REF=main bash

# Turn off the update notice (add to ~/.zshrc)
export ZAPZ_DISABLE_UPDATE_CHECK=1
```
