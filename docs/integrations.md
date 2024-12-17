---
layout: default
title: Integrations
permalink: /integrations/
---

# Integrations

zapz integrates with your favorite development tools.

## VS Code

```yaml
vscode:
  sync_settings: true
  extensions:
    - "dbaeumer.vscode-eslint"
    - "esbenp.prettier-vscode"
  settings:
    "editor.formatOnSave": true
    "editor.defaultFormatter": "esbenp.prettier-vscode"
```

## GitHub

```yaml
github:
  actions: true
  pr_templates: true
  default_branch: "main"
  labels:
    - name: "bug"
      color: "d73a4a"
    - name: "feature"
      color: "0075ca"
```

## Slack

```yaml
notifications:
  slack:
    webhook: "https://hooks.slack.com/..."
    events:
      - "setup_complete"
      - "update_available"
``` 