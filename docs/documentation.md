---
layout: default
title: Documentation
permalink: /docs/
---

# Documentation

## Installation

### Prerequisites

The tool requires these dependencies:
```bash
brew install yq        # YAML processor
```

### One-line Installation

```bash
curl -fsSL https://raw.githubusercontent.com/corbanb/zapz/main/install.sh | bash
```

## Usage

### Basic Commands

```bash
# Show help
zapz --help

# Run with default settings
zapz

# Run with custom config
zapz -c path/to/config.yml

# Run with verbose output
zapz --verbose

# Force reinstall components
zapz --force
```

[Full Documentation →](https://github.com/corbanb/zapz/blob/main/README.md) 