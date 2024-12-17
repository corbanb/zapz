---
layout: default
title: Node.js Development Setup
permalink: /recipes/node
---

# Node.js Development Environment

A complete setup for Node.js development with zapz.

## Quick Setup

```bash
zapz --recipe node
```

## What's Included

- Node.js (via nvm)
- pnpm
- TypeScript
- ESLint
- Prettier
- VS Code Extensions
- Git Hooks

## Configuration

```yaml
node:
  versions:
    - "lts/iron"      # Node.js 20
    - "lts/hydrogen"  # Node.js 18
  default: "lts/iron"
  global_packages:
    - "pnpm"
    - "typescript"
    - "ts-node"
    - "nodemon"

vscode:
  extensions:
    - "dbaeumer.vscode-eslint"
    - "esbenp.prettier-vscode"
    - "christian-kohler.npm-intellisense"

git:
  hooks:
    pre_commit: 
      - "lint-staged"
      - "prettier"
``` 