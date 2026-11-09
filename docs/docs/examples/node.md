---
layout: docs
title: Node.js Setup
icon: fab fa-node-js
description: Example Node.js development environment
permalink: /docs/examples/node/
---

A config for JavaScript and TypeScript work: Node.js, Bun, Deno, pnpm and
TypeScript through [mise](https://mise.jdx.dev), the usual command-line
tools, Ghostty and the recommended shell. It's close to what the setup wizard
writes when you pick **Software development** (see
[Personas and Extras]({{ site.baseurl }}/docs/personas/#software-development)).

## Config

```yaml
git:
  user:
    name: "Your Name"
    email: "you@example.com"
  editor: "code --wait"
  default_branch: "main"
  config:
    pull.rebase: "true"

homebrew:
  formulas:
    - "gh"
    - "jq"
    - "ripgrep"
    - "fd"
    - "mise"
    - "starship"
    - "zsh-autosuggestions"
    - "zsh-syntax-highlighting"
  casks:
    - "visual-studio-code"
    - "ghostty"
    - "orbstack"
    - "font-jetbrains-mono-nerd-font"

languages:
  tools:
    - "node@lts"
    - "bun@latest"
    - "deno@latest"
    - "pnpm@latest"
    - "npm:typescript"

terminal:
  app: "ghostty"

shell:
  setup: "recommended"

cron:
  update_schedule:
    enabled: true
    frequency: "weekly"
    time: "09:00"
    days: ["Monday"]
```

## Run it

```bash
zapz --dry-run -c node.yml   # preview only
zapz -c node.yml
```

Or save it as `~/.local/share/zapz/config/default.yml` and run `zapz`.

## What you get

- mise, with Node.js LTS, Bun, Deno and pnpm as your global versions, and
  TypeScript (`tsc`) installed through mise's npm backend
- a `mise activate` line in your shell, so new terminals use those versions
- OrbStack for containers, and VS Code as your git editor
- Ghostty with the JetBrains Mono Nerd Font, and the recommended shell (Oh My
  Zsh, autosuggestions, syntax highlighting, the Starship prompt)
- a weekly job that runs `brew upgrade` and `mise upgrade`
- Touch ID for `sudo`, the firewall and a FileVault check, since `security`
  is on unless you turn it off

## Variations

Pin an exact version instead of `lts`:

```yaml
languages:
  tools:
    - "node@22.11.0"
```

Use a different version in one project with mise, which writes a `mise.toml`
in that folder:

```bash
cd my-project
mise use node@20
```

### Older configs: nvm

Configs written before mise support use a `node` section, which still works.
zapz installs nvm, your Node versions and global npm packages:

```yaml
node:
  versions: ["lts/lithium", "lts/krypton"]   # Node.js 26 and 24
  default: "lts/lithium"
  global_packages: ["pnpm", "typescript"]
```

New configs should use `languages.tools` instead. See
[node (older configs)]({{ site.baseurl }}/configuration/#node-older-configs).
