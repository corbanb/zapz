## Description
<!-- Describe your changes -->

## Checklist
- [ ] I have tested these changes locally
- [ ] I have updated documentation as needed
- [ ] All tests pass (`./test/test.sh`)
- [ ] Lint checks pass (`npm run lint`)
- [ ] I have added tests that prove my fix/feature works
- [ ] Installation tests pass (`./test/test_install.sh`)
- [ ] ShellCheck passes on all shell scripts
- [ ] YAML files pass yamllint checks

## Status Checks
The following checks must pass before merging:
- Code Quality (lint)
  - ShellCheck
  - YAML Lint
  - Script Formatting
- Tests
  - Core functionality tests
  - Installation tests
  - macOS compatibility tests
- Installation Test
  - Clean install test
  - Update test
- Documentation Build
  - Jekyll build
  - GitHub Pages deployment

## Screenshots
<!-- If applicable, add screenshots to help explain your changes -->

## Testing Steps
```bash
# Run core tests
chmod +x test/test.sh
./test/test.sh

# Run installation tests
chmod +x test/test_install.sh
./test/test_install.sh

# Check shell scripts
shellcheck setup.sh lib/**/*.sh test/*.sh

# Check YAML files
yamllint .github/workflows/ config/
```
