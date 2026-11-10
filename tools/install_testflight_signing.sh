#!/bin/bash
set -euo pipefail
umask 077
dir="$RUNNER_TEMP/ipa-testflight"
mkdir -p "$dir"
kc="$dir/signing.keychain-db"
pw=$(openssl rand -hex 32)
security create-keychain -p "$pw" "$kc"
security unlock-keychain -p "$pw" "$kc"
security set-keychain-settings -lut 3600 "$kc"
printf '%s' "${SIGNING_P12_BASE64:?}" | base64 -D > "$dir/identity.p12"
security import "$dir/identity.p12" -k "$kc" -P "${SIGNING_P12_PASSWORD:?}" -T /usr/bin/codesign
rm "$dir/identity.p12"
security set-key-partition-list -S apple-tool:,apple: -k "$pw" "$kc" >/dev/null
security list-keychains -d user -s "$kc" "$HOME/Library/Keychains/login.keychain-db"
profiles="$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles"
mkdir -p "$profiles"
for target in APP EXT; do
  variable="${target}_PROFILE_BASE64"
  printf '%s' "${!variable}" | base64 -D > "$dir/$target.mobileprovision"
  security cms -D -i "$dir/$target.mobileprovision" > "$dir/$target.plist"
  uuid=$(/usr/libexec/PlistBuddy -c 'Print UUID' "$dir/$target.plist")
  cp "$dir/$target.mobileprovision" "$profiles/$uuid.mobileprovision"
  echo "${target}_PROFILE_UUID=$uuid" >> "$GITHUB_ENV"
done
