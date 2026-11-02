#!/bin/sh
# Remove every rillo.dev.* launchd job from this Mac. Data already copied to
# Cloudflare and the state file on the data drive are left alone.
set -eu
for plist in "$HOME"/Library/LaunchAgents/rillo.dev.*.plist; do
    [ -e "$plist" ] || continue
    label=$(basename "$plist" .plist)
    launchctl bootout "gui/$(id -u)/$label" 2>/dev/null || true
    rm "$plist"
    echo "removed $label"
done
