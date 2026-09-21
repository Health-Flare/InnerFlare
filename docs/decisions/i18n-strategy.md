# Internationalization (i18n) strategy

**Status:** proposed — no code changes yet. This document is the investigation
behind the tracking issues; it captures the honest tradeoffs, not just the
recommendation, so the reasoning survives past the initial implementation.

## Current state

Inner Flare has no i18n today. Every user-facing string in `lib/` is a
hardcoded English string literal. `intl` is not a dependency. There is no
`lib/l10n/`, no `AppLocalizations`, and `MaterialApp` in `lib/main.dart`
doesn't set `locale`, `localizationsDelegates`, or `supportedLocales`, so
even Flutter's own built-in widgets (date pickers, "OK"/"Cancel" labels,
back-button semantics) render in whatever locale list Flutter falls back to.

## What this app's existing constraints rule in and out

This project's non-negotiables (see `CLAUDE.md`, `CONTRIBUTING.md`) shape the
i18n decision more than usual:

- **Fully offline, no network calls, ever.** Any i18n approach that phones
  home for translation strings, usage analytics, or "detect device region"
  IP lookups is disqualified outright, not just discouraged.
- **Minimize dependencies / supply-chain surface.** `CLAUDE.md` already
  states a preference for "one fewer dependency over one more abstraction"
  for storage, and the Renovate config manually gates every new runtime
  dependency because routine-looking bumps have broken this app before. A
  new i18n *package* is a new thing to trust, audit, and keep patched for
  the life of the project.
- **No cloud/analytics/telemetry SDKs of any kind.** Several i18n tools in
  the Flutter ecosystem exist specifically to integrate with a *cloud*
  translation-management platform (Localizely, Lokalise, Crowdin). That
  integration path is not available to us even if the underlying codegen
  tool is otherwise fine to use locally.
- **Predictions/exports must stay byte-for-byte reproducible across
  versions** (`BRIEF.md` §4.2, the backup import/export contract). Anything
  that formats dates/numbers has to be careful not to let UI locale bleed
  into stored or exported data (see "Locale-invariant storage and exports"
  below).

## Options considered

### A. Official `flutter_localizations` + `intl` + `flutter gen-l10n` (recommended)

Flutter's own solution: ARB files (`lib/l10n/app_en.arb`, one per locale) as
the source of truth, `flutter gen-l10n` (a built-in SDK command, not a
separate pub.dev package) generates a typed `AppLocalizations` class from
them, and `intl` (maintained by the Dart team, `dart-lang/i18n`) provides
`DateFormat`/`NumberFormat`/ICU `plural`/`select` support.

**Pros:**
- Zero *additional* pub.dev dependency for the core mechanism —
  `flutter_localizations` ships inside the Flutter SDK itself, and
  `intl` is maintained by the Dart team, not a third party. This is about as
  small a supply-chain footprint as i18n can have in Flutter.
- Compile-time-checked string access (`AppLocalizations.of(context)!.someKey`)
  — a typo or missing translation is a build failure, not a silent blank
  label or raw key shown to a user (a real UX/trust issue in a health app).
- Full ICU MessageFormat support for plurals and gender/select, which is
  necessary correctness, not a nice-to-have — plural rules are
  language-specific (Arabic has six plural categories, not two) and are
  exactly the kind of thing that's a mistake to hand-rewrite.
- No new codegen tool alongside `build_runner`/`riverpod_generator` — it's a
  separate, official SDK command (`flutter gen-l10n`), triggered by
  `flutter: generate: true` in `pubspec.yaml`, and also runs automatically
  as part of `flutter build`/`flutter run`.

**Cons (stated plainly):**
- More ceremony than the alternatives: an `l10n.yaml` config file, ARB's
  verbose JSON-with-`@`-metadata format, and a flat key namespace (no nested
  namespacing like `screens.log.saveButton` — everything is one
  `AppLocalizations` class).
- Regenerating (`flutter gen-l10n`) is an extra manual step during
  development if you're not running `flutter run` (e.g. editing an ARB file
  standalone) — annoying, not fragile.
- Changing locale at runtime (a Settings toggle, not just following system
  locale) needs a small amount of app-side plumbing — a
  `localeProvider` a Riverpod-driven `locale:` on `MaterialApp` — rather than
  being handled for you. Not hard, but not free either.

### B. `easy_localization`

Runtime JSON/CSV/YAML asset-based lookups via `'key'.tr()` extension
methods, no codegen required.

**Pros:** fast to start, no build step, popular, works entirely offline in
its default configuration (it has an optional remote-loading path we would
simply never enable — but that's a footgun that exists in the package,
which the official SDK path doesn't).

**Cons:** a third-party dependency to trust and keep patched indefinitely,
on top of whatever supply-chain gate Renovate already applies. Lookups are
runtime string-keyed, so a typo'd key doesn't fail the build — it fails at
runtime, in front of a user, as a raw key or a blank string. No compile-time
safety. Given this app's stated preference for fewer, better-trusted
dependencies, this is a real regression from option A for not much DX gain.

### C. `slang` (successor to `fast_i18n`)

Codegen-based, JSON/YAML/CSV source files, produces a typed accessor class
similar in spirit to `AppLocalizations` but with nicer DX (nested
namespaces, pluralization helpers, no ARB ceremony).

**Pros:** genuinely nice developer experience, fully offline, typed, active
project.

**Cons:** still a third-party dependency (currently maintained by a small
team, `slang-i18n` on GitHub) for something the Flutter SDK already does
natively. Better DX is a real advantage, but it's not solving a problem
option A can't solve — it's trading "one fewer dependency" for "nicer to
write ARB-equivalent files." Given this app already made that exact
tradeoff explicitly in the other direction for storage (hand-written SQL
over an ORM, see `CLAUDE.md` "Lightweight by Default"), consistency argues
for the same call here.

### D. `intl_utils` / the "Flutter Intl" IDE plugin / Localizely

This tooling wraps `flutter gen-l10n` with a nicer IDE experience — *and*,
depending on setup, can sync ARB files with the Localizely cloud
translation-management platform. The generation-only part isn't materially
different from option A; the cloud-sync part is a hard no per this app's
"no network calls, ever" rule. Not worth adopting a wrapper whose main
extra value proposition is a feature we can't use.

### E. Roll our own (hand-written locale maps, no package at all)

The "fewest possible imports" instinct taken to its conclusion: a
`Map<String, Map<String, String>>` per locale and a manual lookup function,
zero dependencies.

**Rejected.** This looks minimal but isn't — it quietly reimplements CLDR
plural-category logic (which genuinely differs by language and is easy to
get subtly wrong), locale-aware date/number formatting, and RTL text
direction handling, none of which are "a few lines." `intl` already exists,
is maintained by the people who ship Flutter's own SDK localizations, and
solves exactly this. Avoiding it isn't privacy or security hygiene, it's
reinventing a specific, well-known-hard problem with less review than the
option we'd be replacing.

## Decision

**Option A: `flutter_localizations` (SDK) + `intl` (Dart-team-maintained) +
`flutter gen-l10n`.** It has the smallest supply-chain footprint of any
option that actually solves plurals/ICU/RTL/locale formatting correctly,
which is the priority this project has stated for every other dependency
choice so far. The DX cost relative to `slang`/`easy_localization` is real
but small and one-time (mostly: writing ARB instead of JSON).

## What we are deliberately not doing

- No cloud translation-management platform (Localizely, Lokalise, Crowdin,
  or similar) — ARB files are edited and reviewed as plain text in PRs,
  same as every other file in this repo.
- No machine-translation-at-build-time step.
- No IP-based or telemetry-based automatic locale/region detection beyond
  what the OS already exposes via `Platform.localeName` /
  `WidgetsBinding.instance.platformDispatcher.locale` — which is local device
  state, not a network call.
- No third-party i18n package, for the supply-chain reasons above — this can
  be revisited if `gen-l10n`'s ergonomics turn out to be a real blocker in
  practice, but that's a "revisit the decision" conversation, not a default.

## Beyond translation: what else internationalization touches

Translation is the visible 20%. The rest, roughly in the order it'll bite:

1. **Locale-aware date/number formatting.** `intl`'s `DateFormat`/
   `NumberFormat` should replace any ad hoc date string-building once
   locale support exists — cycle-math *computation* stays locale-invariant
   (per `CLAUDE.md`, it's pure and dependency-free already), only its
   *display* becomes locale-aware.
2. **Locale-invariant storage and exports.** The SQLite schema and exported
   backup format (`BRIEF.md` §4.2) must keep storing dates/numbers in a
   fixed, locale-independent form (e.g. ISO-8601) regardless of UI locale —
   otherwise a backup made under a German locale (comma decimal separator,
   DD.MM.YYYY dates) could fail to import under an English one. This needs
   to be an explicit test case, not an assumption.
3. **Pluralization and gender/select rules.** Every existing string that
   embeds a count (cycle day counts, "N symptoms logged", etc.) needs an
   ICU `plural`/`select` rewrite, not string concatenation — this is
   language-specific grammar, not a formatting nicety.
4. **RTL layout.** Arabic/Hebrew support means auditing for hardcoded
   `left`/`right`/`Alignment.centerLeft`-style layout instead of
   `start`/`end`, and checking any custom icons that imply direction (e.g.
   back chevrons). Flutter's `Directionality` handles most of this
   automatically once a locale's `TextDirection` is RTL — the audit is for
   the widgets that quietly assumed LTR.
5. **Text expansion.** Translated strings are commonly 30%+ longer than
   English (German, Finnish) — UI copy that's tightly fit today (buttons,
   dashboard card labels) needs a layout check, not just a translation
   check. This is a natural extension of the existing persona-review
   process (`docs/personas/`) rather than a new process.
6. **Locale-aware sorting.** Any alphabetically-sorted list (e.g. the
   symptom list in Settings) needs collation-aware sorting once non-English
   locales exist, not Dart's default codepoint string comparison.
7. **A locale switcher.** A Settings toggle (follow system / pick a
   language), with the choice persisted. Where that preference lives is a
   small open question — it's not sensitive data (the OS already exposes
   system locale to every app), so it doesn't need to go through the
   encrypted SQLCipher store the way `security_settings` does; a plain local
   preference is proportionate, but this is worth a one-line confirmation
   when that issue is picked up rather than assumed.
8. **Accessibility interplay.** Screen readers (VoiceOver/TalkBack)
   announce in the locale Flutter's `Semantics` tree reports, which falls
   out of setting `localizationsDelegates`/`supportedLocales` correctly —
   worth an explicit check per locale, not just an assumption it "just
   works."
9. **Catching regressions.** New hardcoded strings creeping back in after
   the initial extraction is the most likely long-term failure mode. This
   app already has a pre-commit pattern for exactly this shape of problem —
   `scripts/check_urls.sh` / `.url-scan-ignore` scanning for network URLs in
   Dart files. The same pattern (a small grep-based pre-commit scan, with an
   explicit ignore-file escape hatch) is a natural fit for flagging new
   `Text('literal string')`-shaped widgets that don't go through
   `AppLocalizations`.
10. **Translation accuracy for disclaimer/privacy copy specifically.** This
    app makes explicit claims ("not a medical device," specific privacy
    statements — see `CLAUDE.md` "Privacy-Centric"). A mistranslation of
    those specific strings is a materially different risk than a mistranslated
    button label. Any locale's disclaimer/privacy copy should get a native
    or fluent-speaker review before shipping, even if the rest of that
    locale ships more informally.
11. **Store listings are separate from in-app strings.** Play Store /
    F-Droid metadata (`docs/deployment/*-listing.md`,
    `docs/deployment/fdroid/`) will eventually want translated listings
    too — that's downstream of in-app i18n existing at all, not a blocker
    for it, and is intentionally left out of the issue list below.
12. **Translator contributions.** Once the infrastructure and English
    extraction land, additional locales are a "call for help" — a
    community contributor can add `app_<locale>.arb` and open a PR without
    touching app code. That's tracked as its own issue, deliberately last,
    so there's something concrete to hand people rather than an abstract
    invitation.

## Tracking issues

See [#57](https://github.com/Health-Flare/InnerFlare/issues/57) for the full
breakdown and sub-issues (#58–#65); the infrastructure issue (#58) is the
dependency root for everything else in that list.
