# Changelog

User-facing changes to **Inner Flare** that haven't shipped yet.

Format: [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/).
Versions follow [Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html).

<!--
How to use this file
====================

1. Every PR with a user-visible change adds a line under `## [Unreleased]`
   in the matching subsection (Added, Changed, Deprecated, Removed, Fixed,
   Security). Past tense, plain language, no PR numbers in the text.
   Copy rules from docs/marketing/README.md apply: no medical or diagnostic
   claims, no em dashes.

2. When cutting a release (docs/deployment/release-process.md, step 3),
   write `docs/deployment/release-notes/vX.Y.Z.md` from these entries, then
   rename `## [Unreleased]` to `## [X.Y.Z] - YYYY-MM-DD` and add a fresh,
   empty `## [Unreleased]` above it.

Releases up to 1.3.0 are documented in docs/deployment/release-notes/.
-->

## [Unreleased]

### Changed
- Period starts are now worked out from your whole log, so the order you log days in no longer matters. Day 1 of a cycle is the first day of light, medium or heavy flow. Spotting can lead into a period but doesn't start one, and a single day with no flow inside a period doesn't split it. "How estimates work" explains the rule and its sources.

### Fixed
- Logging a day before an existing period, or clearing flow from a day, no longer leaves an extra or missing period start.
- One-off spotting and single forgotten days inside a period no longer create short 1 to 3 day "cycles" that pulled averages down and could mark your cycles as irregular.
- "Days since last period", counted from the end of your period, no longer stops at a single day you didn't log.

Some cycle lengths, averages and predictions may change after this update, usually by a day.
