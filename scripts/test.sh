#!/bin/sh
# The one way tests run in this repo. Hooks, agents and humans all call this,
# never the bare test command, so how tests run is decided in one place.
#
# Usage: sh scripts/test.sh [--full] [extra args passed to the test runner]
#   (no flag)  the fast run Guard 4 uses at commit
#   --full     the full suite; pre-push runs it (this repo has no CI)
#
# Shards (AGENTS.md, Tests): eval/ is one shard. The app's test targets join
# as the others once the app exists.
set -eu
cd "$(dirname "$0")/.."

[ "${1:-}" = --full ] && shift
# Fast and full are the same while the only suite is eval/'s few-second one.
python3 -I -m unittest discover -s eval -t eval "$@"
