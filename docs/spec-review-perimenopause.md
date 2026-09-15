# Perimenopause/menopause spec review

A review pass over `docs/features/perimenopause.feature`, cross-checked
against `docs/personas.md`, done before implementation starts. Referenced
from `docs/personas.md` (Renata's "open question C1") and from the design
decision comments at the top of `docs/features/perimenopause.feature` — this
is the doc those pointers resolve to.

Four items came out of this review as decisions, one is still open.

## 1. The age-based nudge trigger is cut entirely

The original spec had two nudge triggers: a birth-year-based age check (40+)
and sustained cycle variability. Walking the age path against Renata's
persona surfaced a structural problem, not just a framing one: the age
nudge could only fire once a birth year was on file, but a birth year could
only ever be entered *inside that same nudge*, or via an unprompted Settings
visit most users would never think to make. That's not a trigger reaching
its intended audience — it's a path that mostly can't fire, while still
carrying the cost of storing age as PII and needing its own careful copy.

Decision: drop the age path entirely. Cycle variability is now the sole
trigger. No birth year is collected by this feature at all. See design
decision 1 and the "Introducing the feature" section of
`docs/features/perimenopause.feature`.

## 2. Variability threshold checked against clinical guidance

The 10-day/4-of-6-cycle threshold was originally an internal judgment call,
explicitly flagged as such. Checked against STRAW+10 (the standard clinical
staging criteria for reproductive aging), which defines early perimenopause
variability as a ≥7-day difference between *consecutive* cycles, recurring
within a window of up to 10 cycles.

Decision: keep the existing 10-day/4-of-6 threshold as-is — deliberately
stricter on magnitude than the clinical figure. This is a soft, dismissible,
non-diagnostic nudge, not a staging tool; erring toward under-flagging fits
the app's "never presumptuous" stance better than matching STRAW+10 would.
See design decision 4.

## 3. Symptom tags decoupled from full tracking

Previously, the only way to get the expanded symptom tags (hot flash, night
sweat, etc.) was to accept the variability nudge's offer to enable full
perimenopause tracking — an all-or-nothing choice. The nudge now offers a
third option: add the tags to "Symptoms to track" on their own, disabled by
default, without changing life stage. See design decision 9 and "A user can
add the tags without enabling tracking."

## 4. Daily log screen layout adapts for confirmed menopause

Fern's persona surfaced that Insights adapting wasn't enough — the log
screen's own section ordering still put flow logging first by inherited
default, irrelevant to a life stage where periods aren't expected. Scoped
to "menopause" specifically (not "perimenopause," where periods are still
expected, just less predictable): once life stage is "menopause," symptom
logging leads and flow logging moves down, never hidden. See design
decision 10 and "Daily log screen layout adapts once menopause is
confirmed." `docs/features/log.feature` carries a pointer to this override.

`docs/features/insights.feature` also picked up its own explicit scenarios
mirroring the reproductive-context suppression and life-stage prediction
rules that `perimenopause.feature` owns, rather than leaving them as an
implicit cross-file comment — so an implementer working from either file
alone sees the full behavior.

## Still open: final copy review

Draft wording for the variability nudge, the 12-month menopause observation,
and the pregnancy-recorded confirmation now exists as candidate-copy
comments directly above their scenarios in
`docs/features/perimenopause.feature`. It was pressure-tested in draft
against Renata (anxious, undiagnosed, doesn't want to be told what's
happening to her) and Onyx (pregnancy isn't assumed to be welcome news), but
hasn't had a final review pass. Treat the scenarios as buildable — they only
require "states the reason in one plain sentence," not the literal draft
text — but don't treat the draft wording as locked.

## Related, but decided in `export.feature` directly

The same review session also closed out Dana's persona gap — whether
third-party CSV import (Flo, Clue) rested on a verified premise. It didn't:
Clue exports JSON only, Flo's CSV requires a manual support request. Generic
CSV import was cut from v1 as a result. That decision and its rationale live
in design decision 2 at the top of `docs/features/export.feature`, not
here, since it's an `export.feature`-owned data flow rather than a
perimenopause-specific one.
