#!/bin/sh
# The one way tests run in this repo. Hooks, agents and humans all call this,
# never the bare test command, so how tests run is decided in one place.
#
# Usage: sh scripts/test.sh [--full] [extra args passed to the test runner]
#   (no flag)  the fast run Guard 4 uses at commit
#   --full     the full suite: the tests plus the app build (GitHub's
#              `tests` workflow runs the same two steps)
set -eu
cd "$(dirname "$0")/.."

full=0
[ "${1:-}" = --full ] && { full=1; shift; }

# GitHub's runners (CI=true) have no remote-run; there the command runs bare.
run="$HOME/.claude/scripts/remote-run"
[ "${CI:-}" = true ] && run=

# remote-run changes to the repo root itself, so the package path is explicit.
$run swift test --package-path FluidityCore "$@"

if [ "$full" = 1 ]; then
    # Also proves the app target still compiles.
    sh scripts/build.sh
fi
