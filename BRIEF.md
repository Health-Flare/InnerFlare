# Technical Brief — Cycle Tracking App (working name: "Flo-lite" / TBD)

A menstrual health tracking companion, sibling in spirit to Health Flare: **100% private, fully offline, on-device only.** It should be the lightest thing in this space — smaller dependency footprint, simpler data model, fewer moving parts than Health Flare — while giving the user total control over what's tracked and how it's shown.

## 1. Goals

- Track cycle start/end dates, period days, flow intensity, ovulation estimate, and a small set of symptoms/notes per day.
- Surface cycle length, variability, and predicted fertile/period windows computed **on-device from simple statistics**, not a black-box model.
- Logging a day takes **one screen, a handful of taps, no required fields.**
- The user controls what's visible: which stats/cards appear, in what order, what units, what's collapsed by default.
- Data never leaves the device unless the user explicitly exports it.
- Works identically on iOS and Android; data should be trivially portable between the user's own devices via manual export/import (no cloud, no account).

## 2. Non-goals (for v1)

- No accounts, no sync, no cloud backup, no analytics/telemetry, no ads.
- No AI/ML prediction — cycle/ovulation estimates use transparent, documented statistical methods (e.g. average of last N cycles, standard luteal-phase length) that the user can see the math behind.
- No multi-profile support at v1 (Health Flare's multi-profile model doesn't map cleanly to menstrual tracking — revisit only if there's real demand, e.g. a caregiver tracking a teen's cycle).
- No medical claims. This is a tracking tool, not a diagnostic one — say so clearly in onboarding, the same way Health Flare avoids vague privacy language.

## 3. What carries over from Health Flare

- Flutter + Riverpod, feature-first `lib/features/<feature>/` layout.
- BDD workflow: `docs/features/*.feature` Gherkin scenarios as the source of truth, written before implementation.
- Offline-only enforcement: no network permissions in the manifest, a CI/lint check that fails the build if a URL literal shows up in Dart source (same idea as Health Flare's `.url-scan-ignore` pattern, minus the `healthflare.org`-style exception unless this app gets its own marketing site).
- `flutter analyze` clean, `dart format` enforced, trailing commas, `package:<app>/` imports not relative.

## 4. What's different, and why

### 4.1 Database: skip Isar, use plain SQLite (`sqflite`), no ORM/codegen

Health Flare's own `CLAUDE.md` documents two real costs of Isar Community: a separate codegen project to dodge a generator conflict with Riverpod, and a documented "failed to load dynamic library" failure mode in tests. That's real weight for what this app needs.

The data model here is small and stable: a handful of tables (`cycle_day_logs`, `cycle_summaries`/derived-at-query-time, `settings`). It does not need an object-document mapper, native dynamic libraries per platform, or generated schema classes.

**Recommendation: `sqflite` (or `sqflite_common_ffi` for desktop-based test runs), hand-written SQL, hand-written migrations.**

| Option | Native binaries? | Codegen? | File format | Notes |
|---|---|---|---|---|
| **sqflite (recommended)** | Uses OS-bundled SQLite | None required | Single `.sqlite` file, universal standard | Smallest, most portable, zero codegen. Any SQLite browser can open the file for the user's own audit — that's a real "you control your data" feature, not just a slogan. |
| Isar Community | Yes, per-platform native libs | Yes, separate project (per Health Flare's own troubleshooting notes) | Proprietary binary | Heavier; the exact pain Health Flare already documents fighting. |
| Hive CE | None (pure Dart) | Optional (type adapters) | Proprietary binary box file | Very light, but weaker query capability and a non-standard file format — worse for "openable, portable" data. |
| Sembast | None (pure Dart) | None | JSON-lines file | Lightest possible, human-readable-ish, but no real query engine — fine since dataset is tiny, but gives up SQL for no real benefit here. |
| ObjectBox | Yes, native libs | Yes | Proprietary binary | Similar tradeoffs to Isar; no reason to prefer it here. |

Why SQLite wins for *this* app specifically: cycle math (average cycle length, variability, last-N-cycles windows) is naturally expressed as SQL aggregates, the data volume is trivial (a few thousand rows over a lifetime of use, no performance case for a document store), and — most importantly for "cross-device compatibility" — a single `.sqlite` file is the most durable, tool-agnostic export format there is. Ten years from now, any platform can still read it.

Skip an ORM (Drift, Floor) at v1. Three tables don't need generated query builders; hand-written `sqflite` calls in a thin repository layer are less code and one less build_runner target than the app already has for Riverpod. Revisit Drift only if the schema grows enough that type-safety pays for itself.

### 4.2 Cross-device data portability = an explicit export/import feature, not a sync feature

"Cross device compatibility" should mean: the user can back up on device A and restore on device B, deliberately, offline. Concretely:

- **Export**: copy/serialize the SQLite file (or a JSON dump of it) into a single file the OS share sheet can hand to Files/AirDrop/a USB cable/etc.
- **Import**: pick a file, validate its schema version, replace or merge into the local DB.
- Optional: an app-level passphrase to encrypt the export file at rest (e.g. via `cryptography` package, AES-GCM) since a backup file sitting in Downloads/iCloud Drive is a real exposure if the phone or cloud drive is compromised — worth deciding explicitly rather than defaulting to plaintext.
- Version the schema from day one (`schema_version` in a settings table) so an export from v1.2 can still be imported cleanly by v2.0.

### 4.3 Data model sketch

```
cycle_day_logs
  id (pk)
  date (unique, ISO date)
  period_flow        -- null | spotting | light | medium | heavy
  is_period_start     -- bool, derived or explicit
  symptoms            -- small fixed tag set, stored as a bitmask or joined text; keep it simple
  note                -- free text, optional
  ovulation_test_result -- null | negative | positive (optional, off by default)
  basal_body_temp     -- optional, off by default (v2 candidate, see below)

settings
  key, value           -- luteal phase length assumption, cycle history window (N), which
                          dashboard cards are shown/hidden/reordered, units, reminder prefs
```

Everything derived — cycle length, predicted next period, fertile window, variability — is computed at read time from `cycle_day_logs`, not stored redundantly. Keeps the schema small and avoids stale derived data.

### 4.4 "Ridiculously easy to log" — UX principles

- A single persistent "log today" entry point from the dashboard; defaults to "no period, no symptoms" so a tap-and-done confirms the day with zero required input.
- Flow intensity and symptoms are single-tap toggle chips, not dropdowns or multi-step forms.
- Back-logging (missed yesterday) should be exactly as fast as logging today — don't make the calendar view a second-class citizen.
- Any stat/card on the dashboard can be hidden, reordered, or expanded — store this as user preference in `settings`, never hardcode a "default everyone sees this" layout that can't be turned off.

## 5. MVP scope

**v1:**
- Calendar + quick-log entry (period flow, symptom tags, note)
- Cycle length / period length history
- Predicted next period + fertile window (simple average-based estimate, clearly labeled as an estimate)
- Customizable dashboard (show/hide/reorder cards)
- Local reminders (period due soon, log reminder) via on-device notifications only
- Export/import (plaintext SQLite/JSON file at minimum; encrypted export as a stretch goal)

**v2 candidates (explicitly deferred):**
- Basal body temperature tracking + fertility charting
- Symptom/mood correlation views
- Printable/PDF summary for a doctor visit
- Ovulation test (LH strip) result logging
- Home-screen widget for one-tap logging

## 6. Testing

Same shape as Health Flare: `test/unit` for providers and cycle-math logic (this is the highest-value test surface — get the average/variability/prediction math right and covered), `test/widget` for screens, `docs/features/*.feature` scenarios written before the screens that implement them. Cycle-math functions should be pure and unit-tested exhaustively (edge cases: first-ever cycle with no history, irregular cycles, missing days, DST/timezone boundaries on dates).

## 7. Open assumptions to revisit at repo kickoff

- Single profile only at v1 — confirm this matches actual need before porting Health Flare's multi-profile pattern.
- Plaintext vs. encrypted export as the v1 default — recommend shipping plaintext first with encryption as a fast-follow, rather than blocking v1 on crypto review.
- App name/bundle id/branding — not decided here.
