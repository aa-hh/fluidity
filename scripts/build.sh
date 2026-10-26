#!/bin/sh
# The one way to compile/typecheck this repo. Agents call this, never the bare
# build command (the Claude hook in .claude/hooks/ enforces it).
set -eu
cd "$(dirname "$0")/.."

# GitHub's runners (CI=true) have no remote-run; there the command runs bare.
run="$HOME/.claude/scripts/remote-run"
[ "${CI:-}" = true ] && run=

# Runs on this Mac, not the mule: the signed .app must end up here, and
# remote-run copies nothing back from the mule.
AUDIOUT_REMOTE_LOCAL=1 $run xcodebuild -project Fluidity.xcodeproj -scheme Fluidity -configuration Debug -derivedDataPath .build/DerivedData -quiet build "$@"
echo "Built .build/DerivedData/Build/Products/Debug/Fluidity.app"
