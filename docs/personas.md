# Inner Flare — Personas

Six people spanning the reproductive-life range this app now specs for. Used to
pressure-test framing and copy in `docs/features/*.feature` — not to drive
multi-profile or caregiver features, since Inner Flare is explicitly
single-profile only (BRIEF.md §2). Every persona here is the app's one and
only user, tracking for herself.

Unlike a feature-completeness review, the question each persona asks is
narrower and harder to get right from the spec alone: **would this specific
person feel correctly seen, or would something about how the app talks to her
land wrong** — too clinical, too presumptuous, too alarming, too dismissive,
or just tone-deaf to what she's actually going through. "Framing risk" below
is deliberately the most-used field in this document.

---

## Priya, 24 — baseline, nothing complicating

**Situation:** Cycles are fairly regular. Logs a few times a week. Has never
thought about perimenopause and has no reason to.

**Tech & privacy posture:** Comfortable with apps; picked Inner Flare because
it's offline, not because she has heightened privacy fears.

**Goals:**
- Log flow and symptoms quickly
- See a next-period estimate she can plan around
- Never be asked about anything that doesn't apply to her

**Framing risk:** Any leak of perimenopause-related UI into her experience —
a card, a settings section she stumbles into, a symptom tag she doesn't
recognize — reads as "why is this app talking to me about menopause, I'm
24." She is the entire test of "invisible until relevant." She should be
able to use this app for years without ever knowing the feature exists.

---

## Renata, 46 — mid-transition, undiagnosed, a little anxious

**Situation:** Her cycles started getting unpredictable about four months
ago — some 24 days, some 40. She hasn't brought it up with a doctor yet and
isn't sure if what she's noticing is "normal" or the start of something. She
came to this app already a little on edge about it.

**Tech & privacy posture:** Moderately tech-savvy; chose an offline app
specifically because this feels like a private thing to be tracking, not
something she wants in a cloud account yet.

**Goals:**
- Understand whether what she's seeing is a pattern or noise
- Get language she can eventually use with a doctor
- Not be told what's happening to her by an app

**Framing risk:** The highest-stakes copy in the whole feature. Too clinical
("declining ovarian reserve") reads as a diagnosis the app has no business
making. Too vague ("your cycles are a bit different lately!") reads as
dismissive of something she's genuinely anxious about. Too early or too
insistent a nudge reads as presumptuous — "the app thinks I'm old." **Also
the reason the age-based nudge trigger was cut entirely** — it could only
ever fire for a user who'd already entered a birth year unprompted, which
Renata never would; the variability nudge is now the only path that
actually reaches her. Draft copy for the variability nudge and the
12-month observation is now written (see docs/spec-review-perimenopause.md
and the candidate-copy comments in docs/features/perimenopause.feature) —
still pending final review, no longer a blank gap.

---

## Beca, 29 — hormonal IUD, not perimenopausal

**Situation:** Has a hormonal IUD (Mirena) for endometriosis management, not
contraception. Light, irregular, sometimes entirely absent bleeding is an
expected and medically unremarkable side effect for her — not a sign of
anything changing with age.

**Tech & privacy posture:** Tech-comfortable; hasn't necessarily gone into
Settings to record her IUD yet, because nothing has prompted her to.

**Goals:**
- Track symptoms without the app assuming a "normal" cycle underneath them
- Never be told her bleeding pattern suggests something it doesn't

**Framing risk:** This is the scenario the reproductive-context suppression
exists for, and it only works if the app knows about her IUD *before* it
draws a conclusion from her bleeding pattern. Right now, nothing connects
the two — the variability nudge fires purely off cycle-length variance, and
reproductive context is something she has to think to go record on her own.
A 29-year-old getting a "you might be entering perimenopause" nudge because
of an IUD side effect is exactly the kind of wrong, alarming, and frankly
insulting framing this whole feature is supposed to prevent. **Fixed** —
the variability nudge now asks "something else explain this?" (hormonal
medication, an IUD, or pregnancy) before ever framing the pattern as
perimenopause; see docs/features/perimenopause.feature, "The variability
nudge offers another explanation before assuming perimenopause."

---

## Onyx, 33 — trying to conceive, then early pregnancy

**Situation:** Logging ovulation test results and hoping for a positive.
When she does conceive, the app needs to notice and adapt without making a
big emotional production out of it either way — a wanted pregnancy and one
she's still deciding about should be handled identically by the software.

**Tech & privacy posture:** High engagement with the app during the TTC
window specifically — checks fertile-window predictions often.

**Goals:**
- Trust the fertile-window estimate while trying to conceive
- Have the app adapt smoothly, without assumptions, once she's pregnant

**Framing risk:** The spec already gets this right on the way *out* —
"Ending a recorded pregnancy" explicitly assumes no congratulations or
condolences, neutral copy only, because the app can't know whether that's
good or bad news. That same principle is missing on the way *in*: nothing
currently says recording a new pregnancy is copy-neutral too, and an app
that says "Congratulations!" by default gets it wrong for anyone in Onyx's
position for whom this isn't unambiguously happy news. **Fixed** —
recording a new pregnancy is now specified as copy-neutral, symmetric with
ending one; see docs/features/perimenopause.feature, "Recording a new
pregnancy is copy-neutral, the same as ending one."

---

## Dana, 41 — migrating in from another app for privacy reasons

**Situation:** Three years of history in Flo, switching to Inner Flare
specifically because she doesn't want her cycle data in anyone's cloud.
Exported what she could from her old app before deleting it.

**Tech & privacy posture:** Privacy is the whole reason she's here — this is
the persona the import feature was originally built for. Moderately
tech-savvy; would have been willing to do a column-mapping wizard once, not
interested in re-typing three years of history by hand. **Her core need —
importing directly from Flo — is out of scope for v1** (see Framing risk
below); she's kept in this document because that's a real, named
limitation worth remembering, not a solved case.

**Goals:**
- Bring her history in without losing or misrepresenting any of it
- Never be made to feel judged for having used another app
- Trust that the file she imported from isn't lingering somewhere unencrypted

**Framing risk:** Nothing in the spec's tone was wrong for Dana — the
unrecognized-value mapping and "offer, never force, delete the source file"
scenarios were both good, respectful defaults. The actual risk was upstream
of framing: **the entire CSV-import feature assumed a source app produces a
usable CSV, and that was an unverified premise.** Checked: Clue's export is
JSON only, in a password-protected ZIP, no CSV option; Flo offers CSV but
only via a manual "contact support" request emailed later, not an in-app
download. Neither hands Dana a CSV the way the mapping wizard assumed. **Cut
from v1 rather than shipped on an unverified premise** — see design
decision 2 in docs/features/export.feature. Dana can still move her data in
via InnerFlare's own export/import format on a device-to-device basis; a
from-Flo-or-Clue import path is deferred, not designed around a guess.

---

## Fern, 54 — two years post-menopause, occasional hot flashes

**Situation:** Confirmed menopause in the app two years ago. Still gets
occasional hot flashes and wants a lightweight place to note them. Has zero
interest in anything period-shaped ever again.

**Tech & privacy posture:** Been using the app since before her transition;
not newly onboarding into this feature, so her experience is shaped by
whatever the daily log screen actually looks like now, not just whether
symptom tags exist.

**Goals:**
- Log a hot flash in a few taps
- Never be nagged about periods or shown period-first UI

**Framing risk:** The spec confirms predictions stop and nothing "implies
period logging is still expected" — good coverage for what happens in
Insights. It said nothing, though, about whether the **daily log screen's
own layout** still put flow logging first for her, purely by inherited
default ordering, even though it's irrelevant to her life stage. If the log
screen's visual hierarchy didn't adapt, Fern would experience the app as a
periods app begrudgingly tolerating her rather than one that was actually
built for where she is now. **Fixed** — once life stage is "menopause",
symptom logging now leads and flow logging moves down (never hidden, since
a period after confirmed menopause isn't an error); see
docs/features/perimenopause.feature, "Daily log screen layout adapts once
menopause is confirmed."
