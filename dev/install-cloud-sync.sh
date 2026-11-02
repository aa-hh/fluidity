#!/bin/sh
# Install the launchd job that copies saved dictations to Cloudflare every
# three hours (eval/cloud_sync.py, AA-461). Run from the main checkout, which
# sync-main keeps on origin/main. Remove with dev/purge.sh.
set -eu
repo=$(cd "$(dirname "$0")/.." && pwd)
label=rillo.dev.cloud-sync
plist="$HOME/Library/LaunchAgents/$label.plist"
sed -e "s#{{REPO}}#$repo#g" -e "s#{{HOME}}#$HOME#g" "$repo/dev/cloud-sync.plist.template" > "$plist"
launchctl bootout "gui/$(id -u)/$label" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$plist"
echo "installed $label; log: ~/Library/Logs/$label.log"
