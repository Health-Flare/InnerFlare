# Review personas

Three standing personas used as a review panel for product and UX work on
Inner Flare. They exist so that "is this good?" can be replaced with a
sharper question: **good for whom, doing what, under what constraints?**

| Persona | Age | Lens |
|---------|-----|------|
| [Maya](maya-36-two-children.md) | 36 | Time-poor sceptic. Two children. Logging speed, back-filling, interruption, discretion, unlock friction. |
| [Erin](erin-29-no-children.md) | 29 | Data-literate sceptic. No children, suspected PCOS. Statistical honesty, irregular cycles, clinician-facing use, tone and framing. |
| [Jean](jean-60-post-menopausal.md) | 60 | Post-menopausal outsider. Accessibility, jargon, literal comprehension, and the menopause gap. |

## What these are, and what they aren't

They are **fictional composites**, written to represent constraints that are
well-documented in this product category — not real research participants, and
not a substitute for talking to actual users. A finding sourced from a persona
is a hypothesis with a name attached. It is worth acting on when the persona's
reasoning holds up against the code, and worth discarding when it doesn't.

They are deliberately **critical**. All three are sceptics by construction,
because a panel that likes everything tells you nothing. Their approval is
meant to be hard to get.

They are **not a diversity exercise in demographics**. Each one is here because
she stresses a different axis of the product that the others cannot reach:
Maya stresses the loop under real-world interruption, Erin stresses the truth
claims, Jean stresses who the product excludes.

## How to run a panel review

1. Establish the app's current state first — what is actually implemented,
   not what the feature files specify. The gap between the two is usually
   where the best findings live.
2. Brief each persona separately, with an explicit scope so they don't
   duplicate each other, and tell each one what the others are covering.
3. Require evidence. Every finding cites a `file.dart:line`, a feature-file
   scenario name, a computed value (e.g. a contrast ratio), or a missing
   file. A persona's feelings are input; a persona's assertions are not
   findings until they're grounded.
4. Require credit as well as criticism. A review that only finds faults has
   not told you what to protect.
5. Ask each persona for **the one thing she'd fix first**. Where the three
   disagree on that, you've found the real prioritisation question.

## Shared ground rules for all three

- Each one asks "what does this screen show someone with **no** data,
  **thin** data, or **messy** data?" — never just the happy path.
- Each one reads the interface literally. If a label says something the app
  can't back up, that's a defect, not a wording preference.
- Each one treats the privacy claim as a claim to be **verified**, not a
  brand value to be admired. "No cloud. No accounts. Just you." is a
  testable assertion about permissions, dependencies, and network calls.
- None of them care about internal architecture except where it surfaces:
  a state-restoration bug is their problem, a provider-naming convention
  is not.

## Adding a persona

Keep the panel small. A fourth persona is worth adding only when there is an
axis of the product that none of the three can reach — a partner or
co-viewer, a trans or non-binary user for whom the app's framing is a daily
friction, or a teenager tracking a first cycle would each qualify. A fourth
persona who merely differs in age or occupation would not.
