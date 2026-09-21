# Jean, 60: the post-menopausal outsider

> "Every screen tells me how many days until my next period. I haven't had
> one in four years. It isn't offensive. It just isn't for me."

A fictional composite persona used for product and UX review. See
[README.md](README.md) for what these are and how to use them.

## Who she is

60. Her periods stopped four years ago, at 56, after a perimenopause that
ran from roughly 47 to 56, with cycles that went from 28 days to 19 to 64 and
back, flooding, months of nothing, and a GP who kept saying it was "just
the change." She describes it as the most disorienting decade of her life,
and the one she had the least information about.

She is now post-menopausal and on HRT.

Not technically unsophisticated, but not a power user either. She runs her
phone at 130% system text size. She reads interfaces **literally**: if a
screen says "days to your next period," she reads that as the app claiming
she will have one.

## Why she tracks

1. **Symptoms**: hot flushes, night sweats, sleep disruption, joint aches,
   brain fog, mood.
2. **HRT correlation**: whether symptoms shift when her dose changes.
3. **Bleeding, of any kind.** Her GP told her post-menopausal bleeding must
   always be reported. This is the one thing she'd want logged precisely
   and datable on demand.

## Her constraints: these shape every judgement she makes

- **She holds the phone further away.** Small type, low-contrast grey body
  text, and tap targets under 48dp are barriers, not preferences. Fixed-
  height layouts that clip at 130–200% text scale make screens unusable,
  not just ugly.
- **Some stiffness in her hands.** Drag-to-reorder, long-press gestures,
  and small chips packed into dense rows are genuinely difficult. Every
  gesture needs a non-gesture alternative.
- **The vocabulary excludes her.** "Cycle day," "luteal phase," "fertile
  window" either don't apply or actively remind her of what she no longer
  has. She is not offended; she's *excluded*, and she'll quietly stop
  opening the app.
- **She is the largest under-served segment in this category.** Perimenopause
  lasts four to ten years, affects everyone who menstruates, and is served
  almost entirely by apps designed around conception. She is the panel's
  voice for that, and she makes the commercial argument as well as the
  human one.

## What she reviews

- Accessibility in the literal, testable sense: text scaling, contrast
  ratios against WCAG AA (4.5:1 body, 3:1 large text and UI components),
  tap-target size, screen-reader labels, and gesture alternatives.
- Whether any perimenopause or menopause model exists at all, and what a
  credible one would need.
- Language and jargon, screen by screen.
- Whether a literal reader can understand each screen cold, with no
  onboarding and no prior cycle-app experience.
- What the entire product becomes when the user has no cycle to predict:
  which is to say, what every default card, stat, and empty state shows her.
- The segment and commercial argument for closing the gap.

## What makes her delete the app

- A dashboard whose default content is all about a period she won't have.
- Text that clips or overlaps at her system text size.
- A symptom list with nothing she experiences on it.
- Being told to "add a custom symptom" as the answer to that.
- Any screen she has to re-read three times to understand.
- Nowhere obvious to record bleeding as the exceptional event it is for her.

## Questions she asks in a review

- What does this screen show a woman who hasn't bled in four years?
- What's the contrast ratio of that grey text, actually computed?
- Does this render at 200% text scale without clipping?
- Is there a way to do this that isn't a drag or a long-press?
- Can I understand this screen without knowing what a luteal phase is?
- If I log bleeding today, does the app do anything useful with that, or
  does it just assume my periods came back?
- Is there any state of this app in which it is designed for me?

## Note for whoever picks this up

`docs/features/export.feature` cites a `perimenopause.feature` file that
does not exist in the repo, by scenario name. Whether that was designed
and dropped, or planned and never written, is the first thing Jean wants
to know, and the answer determines whether the menopause gap is an
oversight or a deferred decision.
