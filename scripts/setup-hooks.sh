#!/usr/bin/env bash

# Install a git pre-commit hook that lints and runs the fast test suites
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# shellcheck source=../lib/logging.sh
source "${PROJECT_ROOT}/lib/logging.sh"

hooks_dir="$(git -C "$PROJECT_ROOT" rev-parse --git-path hooks)"
mkdir -p "$hooks_dir"

cat > "$hooks_dir/pre-commit" << 'EOF'
#!/usr/bin/env bash
set -e
cd "$(git rev-parse --show-toplevel)"

if command -v shellcheck >/dev/null; then
    shellcheck -x setup.sh install.sh lib/*.sh lib/modules/*.sh test/*.sh scripts/*.sh
fi
if command -v yamllint >/dev/null; then
    yamllint -c .yamllint .github config/default.yml.example .yamllint
fi
bash test/test.sh >/dev/null
bash test/test_modules.sh >/dev/null
EOF

chmod +x "$hooks_dir/pre-commit"
log_success "Installed pre-commit hook in $hooks_dir"
