#!/usr/bin/env bash

# Run every test suite with the same bash that runs this script, so
# `/bin/bash test/run_tests.sh` on macOS tests under bash 3.2.

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

failed=0
for suite in test.sh test_modules.sh test_install.sh; do
    printf '\n### %s\n' "$suite"
    "$BASH" "$TEST_DIR/$suite" || failed=1
done

if [[ $failed -ne 0 ]]; then
    printf '\nSome test suites failed\n'
    exit 1
fi
printf '\nAll test suites passed\n'
