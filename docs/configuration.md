---
layout: default
title: Configuration
permalink: /configuration/
---

# Configuration Guide

## Default Configuration

zapz comes with sensible defaults for most development environments. Here's what's included:

### Core Development Tools
- ⚙️ Xcode Command Line Tools
- 🍺 Homebrew
- 📦 Git & GitHub CLI
- 🟩 Node.js (via nvm)
- 🏃 Bun & Deno
- 💻 VS Code
- 🖥 iTerm2

### Applications
- 🌐 Arc Browser
- 🎨 Figma
- ⌨️ Cursor
- 💬 Slack
- 🎵 Spotify
- 🔒 1Password

## Custom Configuration

Create your own configuration by copying the example:

```yaml
# config/custom.yml
git:
  user:
    name: "Your Name"
    email: "your.email@example.com"
  editor: "code --wait"

node:
  versions:
    - "lts/hydrogen"
    - "lts/iron"
  default: "lts/iron"
  global_packages:
    - "pnpm"
    - "typescript"
```

## Using GitHub Gist

Share configurations with your team using GitHub Gists:

```bash
zapz -g https://gist.raw.githubusercontent.com/user/gistid/file
```

[View Example Gist →](https://gist.github.com/corbanb/example) 