---
layout: docs
title: Node.js Setup
icon: fab fa-node-js
description: Example Node.js development environment
permalink: /docs/examples/node/
---

A config for JavaScript and TypeScript work: two Node versions through nvm,
global packages, Bun and Deno, and the usual command-line tools.

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

node:
  versions:
    - "lts/krypton"   # Node.js 24
    - "lts/jod"       # Node.js 22
  default: "lts/krypton"
  global_packages:
    - "pnpm"
    - "typescript"

homebrew:
  formulas:
    - "gh"
    - "jq"
    - "ripgrep"
    - "fd"
    - "oven-sh/bun/bun"
    - "deno"
  casks:
    - "visual-studio-code"
    - "iterm2"
    - "docker"

cron:
  update_schedule:
    enabled: true
    frequency: "weekly"
    time: "09:00"
    days: ["Monday"]
```

## Run it

```bash
zapz -c node.yml
```

Or save it as `~/.local/share/zapz/config/default.yml` and run `zapz`.

## What you get

- nvm, with Node.js 24 and 22 installed and 24 as the default in new shells
- `pnpm` and `typescript` installed globally for the default Node version
- Bun (from the `oven-sh/bun` tap, which Homebrew adds automatically) and Deno
- VS Code as your git editor
- a weekly job that runs `brew upgrade` and `npm update -g`

## Variations

Pin exact versions instead of LTS names:

```yaml
node:
  versions: ["22.11.0", "20.18.0"]
  default: "22.11.0"
```

Global packages are installed for whichever version `node.default` points to.
To switch versions in a shell, use nvm as usual:

```bash
nvm use 20.18.0
```
