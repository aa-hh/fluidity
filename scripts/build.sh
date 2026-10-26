#!/bin/sh
# The one way to compile/typecheck this repo. Agents call this, never the bare
# build command (the Claude hook in .claude/hooks/ enforces it).
set -eu
cd "$(dirname "$0")/.."

# Runs on this Mac, not the mule: the signed .app must end up here, and
# remote-run copies nothing back from the mule.
AUDIOUT_REMOTE_LOCAL=1 ~/.claude/scripts/remote-run xcodebuild -project Fluidity.xcodeproj -scheme Fluidity -configuration Debug -derivedDataPath .build/DerivedData -quiet build "$@"
echo "Built .build/DerivedData/Build/Products/Debug/Fluidity.app"
