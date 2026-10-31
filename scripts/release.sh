#!/bin/sh
# Builds a Release copy signed with the Developer ID certificate, has Apple
# notarize it, staples the approval to it and installs it in /Applications.
# Notarization reads the login saved with
# `xcrun notarytool store-credentials notary`; set NOTARY_PROFILE to use another.
set -eu
cd "$(dirname "$0")/.."

products=.build/ReleaseData/Build/Products/Release
app="$products/Fluidity.app"

# Runs on this Mac, not the mule: the signed .app must end up here.
# Base entitlements are left out because they add get-task-allow, which
# notarization rejects.
AUDIOUT_REMOTE_LOCAL=1 "$HOME/.claude/scripts/remote-run" xcodebuild -project Fluidity.xcodeproj -scheme Fluidity -configuration Release -derivedDataPath .build/ReleaseData -quiet build \
  CODE_SIGN_IDENTITY="Developer ID Application" OTHER_CODE_SIGN_FLAGS=--timestamp CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO "$@"
codesign --verify --deep --strict "$app"

rm -f "$products/Fluidity.zip"
ditto -c -k --keepParent "$app" "$products/Fluidity.zip"
xcrun notarytool submit "$products/Fluidity.zip" --keychain-profile "${NOTARY_PROFILE:-notary}" --wait | tee "$products/notary.log"
grep -q "status: Accepted" "$products/notary.log"
xcrun stapler staple "$app"

rm -rf /Applications/Fluidity.app
ditto "$app" /Applications/Fluidity.app
spctl -a -t exec -vv /Applications/Fluidity.app
echo "Installed notarized /Applications/Fluidity.app"
