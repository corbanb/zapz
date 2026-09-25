# zapz roadmap

Open work, most important first. Finished items are in
[CHANGELOG.md](CHANGELOG.md).

## Next

### Verify a full run on a real Mac
CI runs every module against stubs, but nothing has run `zapz` for real yet:
the Xcode dialog, Homebrew, nvm, the Keychain and launchd.

- [ ] Fresh macOS user account (or VM): run the one-line installer, then `zapz`
- [ ] Run `zapz` a second time and confirm nothing is duplicated or reinstalled
- [ ] Confirm the LaunchAgent fires (`launchctl kickstart gui/$(id -u)/com.github.corbanb.zapz.update`)
      and writes `~/Library/Logs/zapz/update.log`
- [ ] Apple Silicon and Intel

### End-to-end test in CI
Add a macOS job that installs from the PR (`ZAPZ_SOURCE=$GITHUB_WORKSPACE`)
and runs `zapz --skip-macos --skip-schedule` with a small config (a couple of
formulas, one Node version), then runs it again to check idempotency. The
runner already has Homebrew, so this is realistic and fairly fast.

### Cut v0.2.0
After merging: bump `ZAPZ_VERSION`, move the Unreleased changelog entries
into a release section, and tag it (see CONTRIBUTING.md). The update notice
only works once releases exist.

## Later

### `--dry-run`
Print what each module would change without changing it. Most modules
already check state before acting, so this is mostly plumbing a flag through.

### Detect apps installed outside Homebrew
Installing a cask whose app is already in `/Applications` currently fails and
is reported as a warning. Checking `brew info --cask --json=v2` for the app
name would let zapz skip it quietly.

### Keep pinned versions current
Dependabot covers GitHub Actions and the docs bundle, but not the nvm version
in `lib/modules/node.sh` or the yq version in `ci.yml`.

## Ideas

- Profiles: named configs for different setups (web, data, mobile)
- Back up changed settings before overwriting them, and restore them later
- Support fish, or other shells beyond zsh and bash
- Health check: confirm the finished setup works (git over SSH to GitHub,
  node on PATH, and so on)
