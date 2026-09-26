#!/usr/bin/env python3
"""Turn pasted "Started: / Ended:" period entries into an Inner Flare backup.

Usage:
  pbpaste | python3 periods_to_backup.py > inner_flare_backup.json
  python3 periods_to_backup.py notes.txt --flow light > inner_flare_backup.json

Then import the file in the app and choose MERGE (not Replace, which would
also reset your symptom catalog).

- Your data has no flow level, but the app only treats a day as a period day
  if it has one, so every period day gets --flow (default: medium; one of
  spotting, light, medium, heavy).
- Lines like "27 days." are ignored. Entry order doesn't matter.
- A "Started" with no "Ended" (ongoing period) becomes a single day.
- Warnings go to stderr so they don't end up in the JSON.
"""
import argparse
import json
import re
import sys
from datetime import date, datetime, timedelta, timezone

# Must be <= the app's schemaVersion (lib/data/database/schema.dart), or the
# app rejects the file as coming from a newer version. Bump if you want to
# match a newer app; leaving it lower is always accepted.
SCHEMA_VERSION = 8
ENVELOPE_VERSION = 1
FLOWS = ("spotting", "light", "medium", "heavy")

ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
ap.add_argument("file", nargs="?", help="input text file (default: stdin)")
ap.add_argument("--flow", choices=FLOWS, default="medium", help="flow level for every period day")
args = ap.parse_args()

text = open(args.file).read() if args.file else sys.stdin.read()

entries = []  # [start, end-or-None], in input order
for line in text.splitlines():
    m = re.match(r"\s*(Started|Ended):\s*(\d{4}-\d{2}-\d{2})", line)
    if not m:
        continue
    d = date.fromisoformat(m.group(2))
    if m.group(1) == "Started":
        entries.append([d, None])
    elif entries and entries[-1][1] is None:
        entries[-1][1] = d
    else:
        print(f"Ignoring 'Ended: {d}' with no matching 'Started'", file=sys.stderr)

days = set()
for s, e in entries:
    if e is None:
        print(f"No end date for period starting {s}; writing just the start day", file=sys.stderr)
        e = s
    if e < s:
        print(f"Skipping entry with end before start: {s} -> {e}", file=sys.stderr)
        continue
    d = s
    while d <= e:
        if d in days:
            print(f"Overlap on {d}; keeping one row", file=sys.stderr)
        days.add(d)
        d += timedelta(days=1)

# is_period_start is recomputed by the app on save (first flow day after a
# day without flow), but we set it correctly anyway.
logs = [
    {
        "date": d.isoformat(),
        "period_flow": args.flow,
        "is_period_start": (d - timedelta(days=1)) not in days,
        "symptoms": [],
        "note": None,
        "ovulation_test_result": None,
        "basal_body_temp_celsius": None,
    }
    for d in sorted(days)
]

backup = {
    "inner_flare_export": True,
    "envelope_version": ENVELOPE_VERSION,
    "encrypted": False,
    "data": {
        "schema_version": SCHEMA_VERSION,
        "exported_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.%fZ"),
        "cycle_day_logs": logs,
        "symptoms": [],
    },
}

json.dump(backup, sys.stdout, indent=2)
sys.stdout.write("\n")
print(f"{len(entries)} periods -> {len(logs)} day logs (flow: {args.flow})", file=sys.stderr)
