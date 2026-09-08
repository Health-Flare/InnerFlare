#!/usr/bin/env bash
# Fails if a network URL (http:// or https://) is found in lib/, unless the
# containing file is listed in .url-scan-ignore (one path per line, '#' comments
# allowed). This app is offline-only — see CLAUDE.md "Must Pass" rule 3.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

ignore_file=".url-scan-ignore"
matches="$(grep -rEln 'https?://' lib/ --include='*.dart' || true)"

if [[ -z "$matches" ]]; then
  echo "No network URLs found in lib/."
  exit 0
fi

flagged=()
while IFS= read -r path; do
  [[ -z "$path" ]] && continue
  if [[ -f "$ignore_file" ]] && grep -Fxq "$path" <(grep -v '^\s*#' "$ignore_file" | sed '/^\s*$/d'); then
    continue
  fi
  flagged+=("$path")
done <<< "$matches"

if [[ ${#flagged[@]} -eq 0 ]]; then
  echo "Network URLs found, but all files are covered by $ignore_file."
  exit 0
fi

echo "Network URL(s) found in files not listed in $ignore_file:" >&2
printf ' - %s\n' "${flagged[@]}" >&2
echo "This app is offline-only. Remove the URL, or add a justified entry to $ignore_file." >&2
exit 1
