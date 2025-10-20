# zapz - TODO List

This document tracks planned improvements and enhancements for the zapz project.

## Recently Completed ✅

- [x] **Auto-install dependencies** - Added automatic yq installation during setup
- [x] **Fixed missing default.yml** - Auto-create config from example template
- [x] **Fixed CONFIG_FILE export** - Ensure all modules can access configuration
- [x] **Clarified "zero dependencies"** - Updated README to reflect auto-installation

## High Priority 🔥

### #4 - Consolidate GitHub Workflows
**Status:** Not Started
**Effort:** Medium
**Impact:** High

Currently have 10 separate workflow files which is difficult to maintain:
- `.github/workflows/lint.yml`
- `.github/workflows/test.yml`
- `.github/workflows/pr-checks.yml`
- `.github/workflows/main.yml`
- `.github/workflows/install-test.yml`
- `.github/workflows/docs-build.yml`
- `.github/workflows/docs-sync.yml`
- `.github/workflows/pages.yml`
- `.github/workflows/release.yml`
- `.github/workflows/dependencies.yml`

**Action Items:**
- [ ] Merge lint, test, and pr-checks into single `ci.yml`
- [ ] Merge docs-build, docs-sync, and pages into single `docs.yml`
- [ ] Keep release.yml and dependencies.yml separate (different triggers)
- [ ] Update documentation to reflect new workflow structure

### #5 - Error Handling in Homebrew Module
**Status:** Not Started
**Effort:** Low
**Impact:** Medium

The `lib/modules/homebrew.sh` module doesn't handle yq command failures gracefully.

**Action Items:**
- [ ] Add dependency checks at start of homebrew module
- [ ] Provide helpful error messages when yq is missing/wrong version
- [ ] Add retry logic for network failures during brew operations
- [ ] Log which formulas/casks fail instead of stopping entirely

**Files to modify:**
- `lib/modules/homebrew.sh`

### #9 - Limited Test Coverage
**Status:** Not Started
**Effort:** High
**Impact:** High

Current tests only check syntax and configuration parsing, not actual functionality.

**Action Items:**
- [ ] Add integration tests using Docker containers
- [ ] Test actual Homebrew installations in isolated environment
- [ ] Test git configuration setup
- [ ] Test SSH key generation
- [ ] Add tests for rollback/cleanup scenarios
- [ ] Test update mechanism
- [ ] Test Gist configuration loading

**Files to modify:**
- `test/test_integration.sh` (new file)
- `test/Dockerfile` (new file for test environment)
- `.github/workflows/test.yml`

## Medium Priority 📋

### #7 - README Too Long
**Status:** Not Started
**Effort:** Medium
**Impact:** Medium

README.md is 555 lines which is hard to scan quickly.

**Action Items:**
- [ ] Keep Quick Start, Features, and basic usage in README
- [ ] Move detailed configuration to `docs/configuration.md`
- [ ] Move troubleshooting to `docs/troubleshooting.md`
- [ ] Move development guide to `docs/development.md`
- [ ] Move GitHub Actions testing to `docs/testing.md`
- [ ] Add clear navigation at top of README
- [ ] Target: Reduce README to ~200 lines

**Files to create/modify:**
- `README.md` (trim down)
- `docs/configuration.md` (expand)
- `docs/troubleshooting.md` (new)
- `docs/development.md` (expand from CONTRIBUTING.md)
- `docs/testing.md` (new)

### #10 - No Automated Versioning
**Status:** Not Started
**Effort:** Medium
**Impact:** Medium

Version is manually managed in `lib/version.sh` which can lead to inconsistencies.

**Action Items:**
- [ ] Implement semantic-release or similar tool
- [ ] Auto-generate version from git tags
- [ ] Auto-update CHANGELOG.md based on commit messages
- [ ] Add version bump commands (major, minor, patch)
- [ ] Ensure version consistency across all files

**Files to modify:**
- `lib/version.sh`
- `package.json` (if adding semantic-release)
- `.github/workflows/release.yml`
- Add `scripts/bump-version.sh`

### #12 - No Rollback Mechanism
**Status:** Not Started
**Effort:** High
**Impact:** Medium

If setup fails midway, there's no way to rollback changes.

**Action Items:**
- [ ] Create state tracking file (`~/.zapz/install-state.json`)
- [ ] Log each installation step with timestamp
- [ ] Implement `zapz rollback` command
- [ ] Track which formulas/casks were installed
- [ ] Track which config files were modified
- [ ] Provide selective rollback (rollback specific components)

**Files to create/modify:**
- `lib/state.sh` (new - state management)
- `lib/rollback.sh` (new - rollback logic)
- `setup.sh` (add state tracking)
- All module files (track installations)

## Nice to Have 🌟

### #6 - Pre-commit Hooks Integration
**Status:** Not Started
**Effort:** Low
**Impact:** Low

The project has `scripts/setup-hooks.sh` but doesn't configure hooks automatically.

**Action Items:**
- [ ] Integrate with husky or simple git hooks
- [ ] Auto-run shellcheck on shell files before commit
- [ ] Auto-run yamllint on YAML files before commit
- [ ] Add commit message format validation
- [ ] Make hooks installation part of dev setup

**Files to modify:**
- `scripts/setup-hooks.sh`
- `install.sh` (add hook setup for dev installs)
- Add `.husky/` directory or simple hooks in `.git/hooks/`

### #8 - Inconsistent Command Examples
**Status:** Not Started
**Effort:** Low
**Impact:** Low

Some examples use `./setup.sh` while others use `zapz`.

**Action Items:**
- [ ] Standardize all examples to use `zapz` command
- [ ] Only show `./setup.sh` in development section
- [ ] Update all documentation files
- [ ] Update code comments

**Files to modify:**
- `README.md`
- `docs/*.md`
- Code comments in all shell files

### #11 - Document Global Variables
**Status:** Not Started
**Effort:** Medium
**Impact:** Low

Variables like `$VERBOSE`, `$FORCE`, `$CONFIG_FILE` are used across modules without clear contracts.

**Action Items:**
- [ ] Add function headers with parameter documentation
- [ ] Document expected global variables at top of each module
- [ ] Add shellcheck directives for external variables
- [ ] Create `docs/development/api.md` documenting module contracts

**Files to modify:**
- All `lib/modules/*.sh` files
- `lib/utils.sh`
- `lib/logging.sh`
- Add `docs/development/api.md`

## Known Issues 🐛

### yq Version Compatibility
**Status:** Not Started
**Effort:** Low
**Impact:** High

The project requires mikefarah/yq (Go version) but some systems may have python-yq installed.

**Action Items:**
- [x] Add yq version detection in setup.sh
- [ ] Add yq version detection in install.sh
- [ ] Update CI to use correct yq version
- [ ] Add troubleshooting docs for yq issues

**Files to modify:**
- `install.sh`
- `.github/workflows/test.yml`
- `docs/troubleshooting.md`

### Git Signing in Test Environment
**Status:** Not Started
**Effort:** Low
**Impact:** Low

Version handling tests fail in some environments due to git commit signing requirements.

**Action Items:**
- [ ] Disable git signing in test environments
- [ ] Add git config to disable signing in test repos
- [ ] Update test setup to handle signing gracefully

**Files to modify:**
- `test/test.sh` (version handling tests)

## Ideas for Future Consideration 💡

- **Plugin System**: Allow users to add custom setup modules
- **Profile Support**: Different configurations for different use cases (web-dev, data-science, etc.)
- **Backup/Restore**: Backup current configuration before making changes
- **Dry Run Mode**: Preview what would be installed without actually installing
- **Dependency Graph**: Visualize what will be installed and why
- **Multi-platform Support**: Extend beyond macOS (Linux, WSL)
- **Interactive Mode**: Prompt user for choices during setup
- **Health Check**: Verify setup is working correctly after installation

---

## Contributing

To work on these items:

1. Create a new branch: `git checkout -b feature/item-number-description`
2. Update this TODO to mark items as "In Progress"
3. Make your changes
4. Update CHANGELOG.md
5. Mark items as complete in this TODO
6. Submit a PR

## Priority Legend

- 🔥 High Priority: Core functionality or major pain points
- 📋 Medium Priority: Important but not urgent
- 🌟 Nice to Have: Quality of life improvements
- 🐛 Known Issues: Bugs or compatibility problems

---

*Last updated: 2025-10-20*
