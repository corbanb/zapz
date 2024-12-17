<div align="center">

# ⚡️ zapz

The zero-dependency macOS development environment setup tool.

[![Version](https://img.shields.io/github/v/release/corbanb/zapz?include_prereleases&label=version)](https://github.com/corbanb/zapz/releases)
[![Tests](https://github.com/corbanb/macos-setup/actions/workflows/test.yml/badge.svg)](https://github.com/corbanb/macos-setup/actions/workflows/test.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![macOS](https://img.shields.io/badge/macOS-Monterey%2B-brightgreen)]()
[![Documentation](https://img.shields.io/badge/docs-corbanb.github.io%2Fzapz-blue)](https://corbanb.github.io/zapz)

[📖 Documentation](https://corbanb.github.io/zapz) | [🚀 Quick Start](#quick-start) | [⚙️ Configuration](#configuration) | [🔍 Examples](https://corbanb.github.io/zapz/examples)

</div>

---

## 🎯 Overview

`zapz` automates the setup of a macOS development environment with a single command. It's perfect for:
- Setting up a new Mac
- Resetting development environments
- Maintaining consistent setups across teams
- Backing up and restoring development configurations

📚 **[Full Documentation Available Here](https://corbanb.github.io/zapz)**

## ✨ Features

- 🔧 **Zero Dependencies**: Works on a fresh macOS installation
- 🎛 **Fully Configurable**: Via YAML or GitHub Gist
- 🔄 **Smart Updates**: Automatic update notifications and easy updating
- 🛡 **Safe Execution**: Idempotent operations, run multiple times safely
- 📝 **Detailed Logging**: Verbose output and error handling
- 🔔 **Update Notifications**: Get notified of new versions when opening your terminal

### What Gets Installed

<details>
<summary>Click to expand installed components</summary>

#### Core Development Tools
- ⚙️ Xcode Command Line Tools
- 🍺 Homebrew
- 📦 Git & GitHub CLI
- 🟩 Node.js (via nvm)
- 🏃 Bun & Deno
- 💻 VS Code
- 🖥 iTerm2

#### Applications
- 🌐 Arc Browser
- 🎨 Figma
- ⌨️ Cursor
- 💬 Slack
- 🎵 Spotify
- 🔒 1Password

#### Development Environment
- SSH key generation
- Git configuration
- Shell preferences
- macOS system settings
</details>

## 🚀 Quick Start

### Prerequisites

First time setup:
```bash
# Make scripts executable (one-time setup)
chmod +x setup.sh test/test.sh lib/modules/*.sh
```

The tool requires these dependencies:
```bash
# Install with Homebrew
brew install yq        # YAML processor
brew install shellcheck  # Shell script linter (optional, for development)
```

### Option 1: One-line Installation
```bash
curl -fsSL https://raw.githubusercontent.com/corbanb/zapz/main/install.sh | bash
```

This will:
- Install the tool to `~/.local/bin/mac-setup`
- Create a `zapz` command in your PATH
- Set up auto-updates
- Install required dependencies if missing

### Option 2: Manual Installation
```bash
# Clone the repository
git clone https://github.com/corbanb/zapz.git
cd zapz

# Install
./install.sh
```

### Usage
```bash
# Show help
zapz --help

# Run with default settings
zapz

# Run with custom config
zapz -c path/to/config.yml
```

## 📖 Usage Guide

### Basic Usage

```bash
./setup.sh                    # Run with default settings
./setup.sh --verbose         # Run with detailed output
./setup.sh --force          # Force reinstall all components
```

### Advanced Options

```bash
Usage: setup.sh [OPTIONS]

Options:
    -h, --help              Show this help message
    -v, --verbose          Enable verbose output
    -f, --force            Force reinstallation of components
    -c, --config FILE      Use custom config file
    -g, --gist URL         Use settings from a GitHub Gist URL
    --skip-macos          Skip macOS preferences setup
    --skip-cron           Skip cron job setup
```

## ⚙️ Configuration

### Using Custom Configuration

1. Create your configuration:
```bash
cp config/default.yml config/custom.yml
```

2. Edit to match your preferences:
```yaml
# custom.yml
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

3. Run with your config:
```bash
./setup.sh -c config/custom.yml
```

### Using GitHub Gist

1. Create a Gist with your configuration
2. Get the raw URL of your Gist
3. Run setup with your Gist:
```bash
./setup.sh -g https://gist.raw.githubusercontent.com/user/gistid/file
```

<details>
<summary>Example Gist Configuration</summary>

```yaml
# Example configuration for web development
homebrew:
  taps:
    - "homebrew/cask"
    - "homebrew/cask-fonts"
  formulas:
    - "git"
    - "gh"
    - "node"
    - "yarn"
  casks:
    - "visual-studio-code"
    - "docker"
    - "figma"

node:
  versions:
    - "lts/iron"
  global_packages:
    - "typescript"
    - "next"

git:
  user:
    name: "Your Name"
    email: "your.email@example.com"
  editor: "code --wait"

macos:
  dock:
    autohide: true
    magnification: true
  keyboard:
    key_repeat: 2
    initial_key_repeat: 15
```
</details>

## 🔄 Maintenance

### Automatic Updates

zapz provides two ways to stay up-to-date:

1. **Terminal Notifications**
- Checks for updates when you open a new terminal
- Shows notifications only once per day
- Provides direct update commands

```bash
# Example notification
🔔 A new version of zapz is available: v0.2.0
   Current version: v0.1.0
   Run 'zapz --update' to update
```

2. **Cron Jobs** that:
- Runs on your configured schedule (daily/weekly/monthly)
- Updates Homebrew packages
- Updates npm global packages
- Runs system health checks
- Sends desktop notifications

#### Update Configuration

Configure updates in your `config.yml`:
```yaml
cron:
  update_schedule:
    enabled: true
    frequency: "daily"    # daily, weekly, or monthly
    time: "00:00"        # When to run (24h format)
    days: ["Sunday"]     # For weekly updates
  terminal_update:
    enabled: true        # Check when opening terminal
    frequency: 86400     # Minimum seconds between checks

cli:
  alias: "zapz"         # Your preferred command alias
  auto_alias: true      # Add alias automatically
```

### Manual Updates

```bash
# Check for updates
zapz --version

# Update zapz
zapz --update

# Force update
zapz --update --force
```

### Disabling Update Notifications

If you prefer not to see update notifications, you can:

1. **Disable in config**:
```yaml
cli:
  update_notifications: false
```

2. **Disable temporarily**:
```bash
# Add to your shell RC file
export ZAPZ_DISABLE_UPDATE_CHECK=1
```

3. **Remove from shell RC**:
```bash
# Edit your .zshrc or .bashrc and remove or comment out:
# zapz update check
```

## 🛠 Development

### Development Dependencies

Additional dependencies for development:
```bash
brew install shellcheck  # Shell script linter
```

### Running Tests

The project includes a comprehensive test suite that verifies both core functionality and installation processes.

#### Prerequisites
```bash
# Required dependencies
brew install yq          # YAML processor
brew install shellcheck  # Shell script linter
```

#### Running the Test Suite
```bash
# Run all tests
./test/run_tests.sh

# Run individual test suites
./test/test.sh         # Run core tests
./test/test_install.sh # Run installation tests

# Run syntax checker
shellcheck setup.sh lib/**/*.sh test/*.sh
```

#### Test Categories

The test suite includes:

1. **Core Tests** (`test.sh`)
   - Module loading and syntax validation
   - Configuration file validation
   - Utility function testing
   - Directory structure verification

2. **Installation Tests** (`test_install.sh`)
   - Clean installation process
   - Update scenarios
   - File permissions
   - PATH configuration
   - Dependency management

#### Continuous Integration

GitHub Actions automatically runs the full test suite:
- On every push to main branch
- For all pull requests
- Tests run on macOS latest

#### Test Output Example

```bash
=== Running All Tests ===
Running test.sh...
✓ Core tests passed

Running test_install.sh...
✓ Installation tests passed

=== All test suites passed ===
```

#### Adding New Tests

To add new tests:
1. Choose the appropriate test file (`test.sh` or `test_install.sh`)
2. Add your test using the `run_test` function:
    ```bash
    run_test "Description of your test" \
        "command_to_test" || ((failed_tests++))
    ```
3. Run the test suite to verify

### Running GitHub Actions Locally

You can test GitHub Actions workflows locally before pushing using [act](https://github.com/nektos/act). This helps catch issues early in your development cycle.

#### Prerequisites

1. Install `act` and Docker:
```bash
# Install act
brew install act

# Install Docker Desktop
brew install --cask docker
```

2. Start Docker Desktop:
   - Open Docker Desktop application
   - Wait for Docker to finish starting up
   - Verify Docker is running: `docker ps`

3. Create required files:
```bash
# Copy default configuration
cp config/default.yml.example config/default.yml

# Create necessary directories
mkdir -p config
```

#### Running Individual Workflows

1. Lint Workflow (Ubuntu-compatible):
```bash
act -j lint -W .github/workflows/lint.yml \
  -P ubuntu-latest=catthehacker/ubuntu:act-latest
```

2. Documentation Sync (Ubuntu-compatible):
```bash
act -j sync-docs -W .github/workflows/docs-sync.yml \
  -P ubuntu-latest=catthehacker/ubuntu:act-latest
```

3. GitHub Pages (Ubuntu-compatible):
```bash
act -j build -W .github/workflows/pages.yml \
  -P ubuntu-latest=catthehacker/ubuntu:act-latest
```

#### Workflows with Limited Local Support

The following workflows require macOS and have limited support in `act`:

1. Test Workflow:
```bash
# Note: Some macOS-specific commands may fail
act -j test -W .github/workflows/test.yml \
  -P ubuntu-latest=catthehacker/ubuntu:act-latest
```

2. Installation Test:
```bash
# Note: Some macOS-specific commands may fail
act -j test-install -W .github/workflows/install-test.yml \
  -P ubuntu-latest=catthehacker/ubuntu:act-latest
```

3. Release Workflow:
```bash
# Note: Tag creation may not work locally
act -j release -W .github/workflows/release.yml \
  -P ubuntu-latest=catthehacker/ubuntu:act-latest
```

#### Running All Workflows

You can run multiple workflows in a few ways:

1. Run workflows individually:
```bash
# Run lint workflow
act -j lint -W .github/workflows/lint.yml -P ubuntu-latest=catthehacker/ubuntu:act-latest

# Run docs-sync workflow
act -j sync-docs -W .github/workflows/docs-sync.yml -P ubuntu-latest=catthehacker/ubuntu:act-latest

# Run pages workflow
act -j build -W .github/workflows/pages.yml -P ubuntu-latest=catthehacker/ubuntu:act-latest
```

2. Run all workflows triggered by an event:
```bash
# Run all workflows that trigger on pull_request
act pull_request -P ubuntu-latest=catthehacker/ubuntu:act-latest

# Run all workflows that trigger on push
act push -P ubuntu-latest=catthehacker/ubuntu:act-latest

# List all available actions
act -l
```

Note: Some workflows might be skipped if they require macOS runners or specific GitHub tokens.

#### Environment Variables and Secrets

For workflows that require secrets:

1. Create a `.secrets` file:
```bash
# .secrets
GITHUB_TOKEN=your_github_token
```

2. Run with secrets:
```bash
act --secret-file .secrets -P ubuntu-latest=catthehacker/ubuntu:act-latest
```

#### Troubleshooting Common Issues

1. **Missing Configuration**:
```bash
# Error: No such file or directory
# Solution: Create required config
cp config/default.yml.example config/default.yml
```

2. **Docker Issues**:
```bash
# Error: Cannot connect to Docker daemon
# Solution: Start Docker Desktop and wait
```

3. **Permission Issues**:
```bash
# Error: Permission denied
# Solution: Ensure files are executable
chmod +x setup.sh test/*.sh lib/modules/*.sh
```

## 🔍 Troubleshooting

<details>
<summary>Common Issues</summary>

### Permission Denied
```bash
chmod +x setup.sh
```

### Homebrew Installation Fails
- Ensure you have internet connection
- Run `xcode-select --install` manually

### Configuration Not Loading
- Verify YAML syntax
- Check file permissions
- Ensure correct file path

### Permission Denied
+ If you get permission errors or "files are not executable" errors:
```bash
# Make all scripts executable
chmod +x setup.sh
chmod +x test/test.sh
chmod +x lib/modules/*.sh
```
</details>

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 🙏 Acknowledgments

- [Homebrew](https://brew.sh)
- [nvm](https://github.com/nvm-sh/nvm)
- [GitHub CLI](https://cli.github.com)

---

<div align="center">
Made with ❤️ by @corbanb
</div>
