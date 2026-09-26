#!/usr/bin/env bash
# Launch Inner Flare on an iOS Simulator in a clean "recording" mode, for
# making your own videos or screenshots: no debug chrome or DEBUG ribbon,
# demo data seeded, no Face ID prompt, status bar set to 9:41 / full
# battery. See tool/video_mode.dart for exactly what it changes.
#
# Usage: scripts/video_mode.sh [iphone|ipad|<simulator name or UDID>] [flags]
#   iphone (default)   iPhone 11 Pro Max, the App Store 6.5" capture device
#   ipad               iPad Pro 13-inch (M4), the App Store iPad capture device
#
# Flags:
#   --keep-data    keep the app's existing data instead of replacing it with
#                  the demo dataset. By default this REPLACES all logs and the
#                  dashboard layout in the simulator's copy of the app.
#   --fixed-clock  freeze "now" at 2026-09-25 09:41 (docs/marketing/specs)
#
# Record with Cmd+R in the Simulator app (File > Record Screen), or
#   xcrun simctl io booted recordVideo out.mov      (Ctrl+C to stop)
# Turn on Do Not Disturb yourself (simctl can't): swipe down > Focus.
# Press q in this terminal to quit; the status bar override is cleared then.

set -euo pipefail
cd "$(dirname "$0")/.."

target="iphone"
defines=(--dart-define=SCREENSHOT_MODE=true)
for arg in "$@"; do
  case "$arg" in
    --keep-data) defines+=(--dart-define=VIDEO_RESEED=false) ;;
    --fixed-clock) defines+=(--dart-define=VIDEO_FIXED_CLOCK=true) ;;
    -*) echo "Unknown flag: $arg" >&2; exit 2 ;;
    *) target="$arg" ;;
  esac
done

case "$target" in
  iphone) name="iPhone 11 Pro Max" ;;
  ipad) name="iPad Pro 13-inch (M4)" ;;
  *) name="$target" ;;
esac

# Match a UDID or a simulator name; prefer one that's already booted.
udid=$(NAME="$name" python3 - <<'PY'
import json, os, subprocess
want = os.environ["NAME"]
data = json.loads(subprocess.check_output(
    ["xcrun", "simctl", "list", "devices", "available", "-j"]))["devices"]
matches = [d for ds in data.values() for d in ds
           if want in (d["name"], d["udid"])]
matches.sort(key=lambda d: d["state"] != "Booted")
print(matches[0]["udid"] if matches else "")
PY
)
if [ -z "$udid" ]; then
  echo "No available simulator named or numbered '$name'. See: xcrun simctl list devices available" >&2
  exit 1
fi

echo "Using simulator: $name ($udid)"
xcrun simctl boot "$udid" 2>/dev/null || true
open -a Simulator
xcrun simctl bootstatus "$udid" -b >/dev/null

xcrun simctl status_bar "$udid" override --time 9:41 \
  --batteryState charged --batteryLevel 100 --wifiBars 3 --cellularBars 4
trap 'xcrun simctl status_bar "$udid" clear' EXIT

if [[ " ${defines[*]} " != *VIDEO_RESEED=false* ]]; then
  echo "Replacing this simulator's Inner Flare data with the demo dataset (use --keep-data to skip)."
fi

flutter run -d "$udid" -t tool/video_mode.dart "${defines[@]}"
