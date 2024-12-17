---
layout: default
title: CLI Reference
permalink: /cli/
---

# CLI Reference

## New Commands

### System Management

```bash
# Check system health
zapz doctor

# Export current config
zapz export > my-config.yml

# Share config (creates gist)
zapz share

# Backup environment
zapz backup

# Restore from backup
zapz restore [backup-file]
```

### Component Management

```bash
# List installed components
zapz list

# Clean unused components
zapz clean

# Update specific components
zapz update [component]
```

### Team Features

```bash
# Initialize team config
zapz init-team

# Apply team standards
zapz standards

# Run onboarding
zapz onboard
``` 