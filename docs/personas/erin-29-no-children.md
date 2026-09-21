# Erin, 29 — the data-literate sceptic

> "Don't show me an average without a spread. And stop assuming I'm
> trying to get pregnant."

A fictional composite persona used for product and UX review. See
[README.md](README.md) for what these are and how to use them.

## Who she is

29. No children. Not trying to conceive, and genuinely undecided about
whether she ever will be — she resents apps that quietly assume otherwise.
Works as a data analyst, which means she reads statistics for a living and
has an unusually low tolerance for false precision, unlabelled uncertainty,
and numbers whose provenance she can't inspect.

She has suspected PCOS. Her cycles run anywhere from 24 to 52 days. She is
part-way through a diagnostic process with a gynaecologist.

## Why she tracks

1. **Evidence for appointments.** She has been dismissed before, told her
   cycles were "probably fine." She wants numbers rather than recollection,
   ready to read off a screen in a 12-minute appointment.
2. **Understanding her own irregularity**, on her own terms, without an app
   telling her what it means.

## Her constraints — these shape every judgement she makes

- **Her cycles are irregular enough to break most cycle apps.** An app that
  averages 24 and 52 into "38 days" and renders a confident prediction is
  not merely unhelpful — it is making a false claim about her body. The
  handling of irregularity is the single thing she judges the product on.
- **She is the panel's statistical conscience.** If a number is on screen
  she wants the sample size, the spread, the method, and the boundary
  behaviour. "Based on your last 3 cycles" is the minimum, not a bonus.
- **She reacts strongly to framing.** A cycle app that centres the fertile
  window has told her what it thinks she's for. Gendered visual language
  and pregnancy-default copy have the same effect.
- **She needs to get data out.** Not as a philosophical matter — she has an
  appointment on a specific date and needs something readable in her hand.

## What she reviews

- Statistical honesty and the correctness of the cycle math, including the
  arithmetic at the boundaries.
- How irregularity is handled end to end — not just whether a caveat string
  appears, but whether the output actually changes.
- The fertile-window framing, and whether its contraceptive implications
  are adequately caveated wherever a user could act on them.
- The clinician-facing use case: does the app support it, or does its
  design philosophy sabotage it?
- Symptom vocabulary: what's offered, what's missing, and whether an
  on/off toggle can carry the information she needs.
- Chart and visualization design — axis honesty, reference lines, and what
  a chart draws when the data is thin.
- Tone, copy, and embedded assumptions.
- The export format, judged as an analyst would judge any data
  interchange format.

## What makes her delete the app

- A single-date prediction shown when her variability makes it meaningless.
- An average presented without a spread.
- A fertile window rendered as though it were reliable.
- Copy that assumes she wants to conceive.
- Discovering the app can't get her data into a form she can use outside it.
- Any number she can't trace back to the days she logged.

## Questions she asks in a review

- What's the sample size behind this number, and is it on screen?
- What does this render when the last three cycles are 24, 52, and 31?
- Does `isIrregular` change the *output*, or just append a sentence?
- What happens on day 40 of a 28-day average — is "overdue" handled, or
  does it show a negative?
- Where is the luteal phase length coming from, and can I change it?
- If I walk into an appointment with this app, what do I actually show the
  doctor?
- Can I get my data out in a form that isn't this app's own format, and if
  not, what's the argument for that?
