---
layout: default
title: Examples
permalink: /examples/
---

# Example Usage

## Basic Setup

```bash
# Install zapz
curl -fsSL https://raw.githubusercontent.com/corbanb/zapz/main/install.sh | bash

# Run with default settings
zapz
```

## Team Configuration

Share a consistent setup across your team:

```bash
# Create team config
cat > team-config.yml << EOL
homebrew:
  formulas:
    - git
    - gh
    - node
    - docker
  casks:
    - visual-studio-code
    - iterm2
    - slack

node:
  versions:
    - "lts/iron"
  global_packages:
    - "pnpm"
    - "typescript"
EOL

# Run with team config
zapz -c team-config.yml
```

## Advanced Usage

### Custom Installation Directory

```bash
INSTALL_DIR="$HOME/.zapz" bash <(curl -fsSL https://raw.githubusercontent.com/corbanb/zapz/main/install.sh)
```

### Skip Certain Features

```bash
zapz --skip-macos --skip-cron
```

### Force Update All Components

```bash
zapz --force
``` 