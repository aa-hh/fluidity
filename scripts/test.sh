#!/bin/sh
# The one way tests run in this repo. Hooks, agents and humans all call this,
# never the bare test command, so how tests run is decided in one place.
#
# Usage: sh scripts/test.sh [--full] [extra args passed to the test runner]
#   (no flag)  the fast run Guard 4 uses at commit
#   --full     the full suite; pre-push runs it (this repo has no CI)
set -eu
cd "$(dirname "$0")/.."

full=0
[ "${1:-}" = --full ] && { full=1; shift; }

# remote-run changes to the repo root itself, so the package path is explicit.
~/.claude/scripts/remote-run swift test --package-path FluidityCore "$@"

if [ "$full" = 1 ]; then
    # Pre-push also proves the app target still compiles.
    sh scripts/build.sh
fi
