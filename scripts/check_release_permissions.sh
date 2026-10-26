#!/usr/bin/env bash
# Fails if the release APK asks for a permission that isn't in
# scripts/release_permissions.txt, or for any network permission at all.
#
# This reads the built APK, not android/app/src/main/AndroidManifest.xml:
# plugins merge their own manifests in, so the source manifest alone can't
# show what ships. Network permissions fail even if someone adds them to
# the allowlist, because "no internet permission" is a public claim.
#
# Usage: scripts/check_release_permissions.sh path/to/app-release.apk
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

apk="${1:?usage: $0 path/to/app-release.apk}"
allow_file="scripts/release_permissions.txt"

aapt2="${AAPT2:-}"
if [[ -z "$aapt2" ]]; then
  sdk="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}}"
  aapt2="$(ls -d "$sdk"/build-tools/*/aapt2 2>/dev/null | sort -V | tail -1 || true)"
fi
if [[ -z "$aapt2" || ! -x "$aapt2" ]]; then
  echo "aapt2 not found. Set AAPT2 or ANDROID_HOME." >&2
  exit 2
fi

perms="$("$aapt2" dump permissions "$apk" | sed -nE "s/^uses-permission: name='([^']+)'.*/\1/p" | sort -u)"
if [[ -z "$perms" ]]; then
  echo "No permissions read from $apk; refusing to pass on an empty result." >&2
  exit 2
fi

echo "Release APK permissions:"
echo "$perms" | sed 's/^/ - /'

fail=0
network_pattern='^android\.permission\.(INTERNET|ACCESS_NETWORK_STATE|ACCESS_WIFI_STATE|CHANGE_NETWORK_STATE|CHANGE_WIFI_STATE|CHANGE_WIFI_MULTICAST_STATE|NEARBY_WIFI_DEVICES|BLUETOOTH|BLUETOOTH_CONNECT|BLUETOOTH_ADVERTISE|BLUETOOTH_SCAN)$|^com\.google\.android\.c2dm\.permission\.RECEIVE$'
network="$(echo "$perms" | grep -E "$network_pattern" || true)"
if [[ -n "$network" ]]; then
  echo "Network permission(s) in the release APK:" >&2
  echo "$network" | sed 's/^/ - /' >&2
  echo "Inner Flare must ship with no network access. Find the plugin that added it" >&2
  echo "and remove it with tools:node=\"remove\" in the main manifest, or drop the plugin." >&2
  fail=1
fi

allowed="$(grep -vE '^\s*(#|$)' "$allow_file" | awk '{print $1}' | sort -u)"
new="$(comm -23 <(echo "$perms") <(echo "$allowed"))"
if [[ -n "$new" ]]; then
  echo "Permission(s) not in $allow_file:" >&2
  echo "$new" | sed 's/^/ - /' >&2
  fail=1
fi

[[ $fail -eq 0 ]] && echo "OK: no network permissions, nothing outside $allow_file."
exit $fail
