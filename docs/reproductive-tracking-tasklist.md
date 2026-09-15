# Reproductive tracking spec: task list

Tracks what's left before `docs/features/perimenopause.feature`,
`docs/features/export.feature`, and `docs/features/insights.feature` go from
spec to implementation. See `docs/spec-review-perimenopause.md` for the
review that produced most of this, and `docs/personas.md` for the framing
rationale behind each item.

## Before implementation starts

- [ ] **Final copy review.** Candidate wording exists for the variability
  nudge, the 12-month menopause observation, and the pregnancy-recorded
  screen — see the "Candidate copy" comments directly above their
  scenarios in `docs/features/perimenopause.feature`. Pressure-tested in
  draft against Renata and Onyx, but not yet a locked final pass. The
  Gherkin scenarios only require "states the reason in one plain sentence,"
  so implementation isn't blocked on this — but don't ship the draft
  wording as final without a read-through first.
- [ ] Decide whether `docs/features/symptom_settings.feature` needs its own
  scenario for how tags added via "add the tags without enabling tracking"
  (`perimenopause.feature`) show up in the "Symptoms to track" screen —
  the perimenopause spec describes the behavior, but symptom_settings.feature
  itself doesn't yet reference it.

## Implementation, once specs are approved

- [ ] `reproductive_context_settings` table + migration (schema_version
  bump) — columns per `perimenopause.feature`'s "Reproductive context: HRT,
  IUD, and pregnancy" section. Part of export/import.
- [ ] `nudge_state` table + migration — one row per nudge id
  (`perimenopause_variability` only now that the age path is cut). Per-device,
  NOT part of export/import.
- [ ] `life_stage_settings` (or equivalent field) — unset / perimenopause /
  menopause. Per-device, NOT part of export/import per spec (life stage
  itself round-trips; nudge deferral state doesn't).
- [ ] Cycle-math: low-confidence prediction labeling for sustained
  perimenopause variability, and prediction suppression for
  reproductive-context flags / confirmed menopause — pure functions, unit
  test against the scenarios in `insights.feature`'s new "Life stage and
  reproductive context adjust predictions" section.
- [ ] Daily log screen: symptom-first layout when life stage is
  "menopause" specifically (not "perimenopause") — see
  `perimenopause.feature`'s "Daily log screen layout adapts once menopause
  is confirmed" and the pointer left in `log.feature`.
- [ ] Expanded symptom tag set (hot flash, night sweat, sleep disruption,
  brain fog, joint aches) gated behind life stage, plus the "add tags
  without enabling tracking" path that adds them disabled-by-default.
- [ ] Variability nudge UI: three-option pattern (enable tracking /
  something else explains this / add tags only) + generic
  defer/dismiss/don't-ask-again pattern from "Nudge transparency and
  deferral" — written generically enough to reuse for future nudges.
- [ ] Reproductive context settings screen (HRT flag, IUD type, pregnancy +
  optional dates) with the precedence rules from "Pregnancy takes
  precedence over IUD or HRT status when both are recorded."

## Explicitly deferred, not forgotten

- **Generic CSV import from other cycle-tracking apps** — cut from v1
  after confirming Clue exports JSON-only and Flo's CSV requires a manual
  support request (see design decision 2 in `export.feature`). Revisit
  only once a real third-party source is confirmed to produce something
  this app can honestly claim to read — don't resurrect the
  column-mapping wizard on the old assumption.
- **Platform health store import** (Apple Health / Health Connect) —
  scoped as its own later phase in `export.feature`, unrelated to the CSV
  decision above. Bigger lift: native permission grants + platform APIs,
  not a file picker.
- **Age-based nudge trigger** — removed, not deferred. See design
  decision 1 in `perimenopause.feature` for why it doesn't come back in
  its original form; if age-awareness is wanted later, it needs a
  different collection mechanism than "ask inside the nudge that needs
  age to already be known."

## Pre-PR checks (done as of this pass)

- [x] `flutter analyze` — no issues
- [x] `dart format --set-exit-if-changed .` — clean
- [x] `./scripts/check_no_network_urls.sh` — clean
- [x] No `lib/` code references any of the removed concepts (birth year,
  age-based nudge id, CSV import field mappings) — spec-only branch, safe
  to merge without a code migration
