# Contributing to zapz

Thank you for your interest in contributing to zapz! This document provides guidelines and workflows to ensure smooth collaboration.

## Development Workflow

### 1. Setting Up Your Development Environment

```bash
# Clone the repository
git clone https://github.com/corbanb/zapz.git
cd zapz

# Install dependencies
brew install act shellcheck yamllint

# Set up git hooks
./scripts/setup-hooks.sh

# Copy and configure secrets
cp .secrets.example .secrets
# Edit .secrets with your GitHub token
```

### 2. Development Process

#### Before Making Changes
```bash
# Create a new branch
git checkout -b feature/your-feature-name

# Run quick test to ensure clean slate
./test/run_actions.sh local lint
```

#### During Development
Use VS Code tasks (Cmd/Ctrl + Shift + P, then "Run Task"):
- "Quick Test": Fast validation during development
- "Lint Only": Check code style
- "Run All Tests": Full test suite
- "Check PR Ready": Complete validation before PR

Or run from terminal:
```bash
# Quick validation
./test/run_actions.sh local lint

# Full test suite
./test/run_tests.sh

# All workflows
./test/run_actions.sh local all
```

#### Before Committing
The pre-commit hook will automatically run:
- Linting checks
- Core tests
- Secrets detection

#### Before Pushing
The pre-push hook will automatically run:
- Full test suite
- All workflows locally

### 3. Creating Pull Requests

1. **Prepare Your Changes**
```bash
# Ensure all tests pass
./test/run_actions.sh local all --with-release

# Update documentation if needed
vim docs/documentation.md  # or use your preferred editor
```

2. **Create Pull Request**
- Use conventional commit format for PR title:
  - Format: `type(scope): description`
  - Types: feat, fix, docs, style, refactor, test, chore
  - Example: `feat(core): add new installation option`

3. **PR Requirements**
- Detailed description of changes
- All checks passing
- Documentation updated (if applicable)
- No draft status
- No auto-merge enabled

### 4. Running GitHub Actions Locally

#### Using VS Code
1. Open Command Palette (Cmd/Ctrl + Shift + P)
2. Type "Run Task"
3. Choose desired test task

#### Using Terminal
```bash
# Run specific workflows
./test/run_actions.sh local lint    # Linting only
./test/run_actions.sh local test    # Test suite
./test/run_actions.sh local docs    # Documentation

# Run all workflows
./test/run_actions.sh local all

# Run with release workflow
./test/run_actions.sh local all --with-release
```

#### Running on GitHub
```bash
# Run workflows remotely
./test/run_actions.sh remote lint
./test/run_actions.sh remote all
```

### 5. Troubleshooting

#### Common Issues

1. **Workflow Permission Errors**
```bash
# Check secrets file
cat ~/.local/bin/.secrets
# Ensure GITHUB_TOKEN is set correctly
```

2. **Local Action Runner Issues**
```bash
# Update act
brew upgrade act

# Clean Docker containers
docker system prune
```

3. **Test Failures**
```bash
# Run with verbose output
VERBOSE=true ./test/run_tests.sh

# Check specific workflow
./test/run_actions.sh local lint -v
```

### 6. Code Style

- Shell scripts: Follow [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- YAML: Follow [YAML Style Guide](https://yamllint.readthedocs.io/en/stable/rules.html)
- Markdown: Use [CommonMark](https://commonmark.org/) specification

### 7. Getting Help

- Open an issue for bugs or feature requests
- Join discussions in existing issues
- Check the [documentation](https://corbanb.github.io/zapz)

## License

By contributing to zapz, you agree that your contributions will be licensed under the MIT License.
