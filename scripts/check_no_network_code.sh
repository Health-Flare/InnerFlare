#!/usr/bin/env bash
# Fails if anything that can reach the network is added to the app without
# someone deciding it should be. Inner Flare is offline-only (CLAUDE.md
# "Must Pass" rule 3). Three checks, all on source, so it runs in seconds:
#
#   1. Dart network APIs in lib/ (sockets, HTTP clients, network images,
#      networking packages). URL literals are checked separately by
#      scripts/check_no_network_urls.sh, which this script also runs.
#   2. iOS Info.plist keys that only a networking app needs (App Transport
#      Security exceptions, local network access, Bonjour).
#   3. Every package in pubspec.lock must be listed in
#      scripts/allowed_packages.txt. A new package, direct or transitive,
#      fails until someone checks what it does and adds it on purpose.
#
# The release APK's permissions are checked after the build by
# scripts/check_release_permissions.sh. Neither check proves the app makes
# no network calls at runtime; they stop new ways of doing it from landing
# unnoticed.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

fail=0

echo "== URL literals in lib/"
./scripts/check_no_network_urls.sh || fail=1

echo "== Network APIs in lib/"
# Word-boundaried names from dart:io and Flutter that open a connection,
# plus imports of packages whose only job is networking.
api_pattern='\b(HttpClient|HttpServer|HttpOverrides|WebSocket|RawSocket|RawDatagramSocket|SecureSocket|RawSecureSocket|ServerSocket|Socket|InternetAddress|NetworkInterface|NetworkImage|NetworkAssetBundle)\b|Image\.network|package:(http|dio|web_socket_channel|web_socket|http2|grpc|shelf|socket_io_client|connectivity_plus|firebase_[a-z_]+|sentry[a-z_]*)/|dart:html'
hits="$(grep -rEn "$api_pattern" lib/ --include='*.dart' | grep -vE '^[^:]+:[0-9]+:\s*//' || true)"
if [[ -n "$hits" ]]; then
  echo "Network API use found in lib/:" >&2
  echo "$hits" >&2
  echo "Inner Flare is offline-only. Remove it; this check has no ignore list on purpose." >&2
  fail=1
else
  echo "None."
fi

echo "== iOS network keys in Info.plist"
plist_hits="$(grep -nE 'NSAppTransportSecurity|NSAllowsArbitraryLoads|NSExceptionDomains|NSLocalNetworkUsageDescription|NSBonjourServices' ios/Runner/Info.plist || true)"
if [[ -n "$plist_hits" ]]; then
  echo "Network-related keys in ios/Runner/Info.plist:" >&2
  echo "$plist_hits" >&2
  fail=1
else
  echo "None."
fi

echo "== Packages in pubspec.lock vs scripts/allowed_packages.txt"
allow_file="scripts/allowed_packages.txt"
locked="$(awk '/^packages:/{f=1;next} f&&/^[^ ]/{f=0} f&&/^  [a-z_0-9]+:$/{gsub(/[: ]/,"");print}' pubspec.lock | sort -u)"
allowed="$(grep -vE '^\s*(#|$)' "$allow_file" | awk '{print $1}' | sort -u)"
new="$(comm -23 <(echo "$locked") <(echo "$allowed"))"
if [[ -n "$new" ]]; then
  echo "Packages in pubspec.lock that aren't in $allow_file:" >&2
  echo "$new" | sed 's/^/ - /' >&2
  echo "Check what each one does (does it open sockets, call HTTP, ship native" >&2
  echo "code that does?), then add it to $allow_file with a short note." >&2
  fail=1
else
  echo "All $(echo "$locked" | wc -l | tr -d ' ') packages are allowed."
fi
stale="$(comm -13 <(echo "$locked") <(echo "$allowed"))"
if [[ -n "$stale" ]]; then
  echo "Note: in $allow_file but no longer locked (safe to remove):"
  echo "$stale" | sed 's/^/ - /'
fi

exit $fail
