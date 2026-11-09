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
- [ ] Try the wizard, `--dry-run`, declining at "Continue?", and `--configure`

### End-to-end test in CI
Add a macOS job that installs from the PR (`ZAPZ_SOURCE=$GITHUB_WORKSPACE`)
and runs `zapz --skip-macos --skip-schedule` with a small config (a couple of
formulas, one Node version), then runs it again to check idempotency. The
runner already has Homebrew, so this is realistic and fairly fast.

### Cut v0.2.0
`ZAPZ_VERSION` is already 0.2.0 on this branch. After merging, date the
0.2.0 changelog entry and tag the merge commit `v0.2.0` (see CONTRIBUTING.md).
The docs' `ZAPZ_REF=v0.2.0` examples and the update notice depend on that
release existing.

### Web config builder
A page on the docs site for building a config visually: start from the
personas and packs in `catalog/`, pick apps from tiles, toggle macOS
settings, and see the YAML update live. It ends with a copy-paste install
command for exactly that setup (for example a Gist link passed to
`zapz --gist`). Good for teams onboarding new hires.

## Later

### `zapz capture`: copy setup from an old Mac
Write a config from an existing Mac (installed Homebrew packages and apps,
git settings, Node versions, the macOS settings zapz manages), optionally to
a private Gist, so a new Mac can be set up to match with one command. Could
also read and write a Homebrew `Brewfile`.


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
