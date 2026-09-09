# Contributing to InnerFlare

Thanks for taking a look at InnerFlare. This is a small, offline-only,
privacy-first project — contributions are welcome, but a few things about
how it's built are non-negotiable (see "Ground rules" below) precisely
because they protect that.

By contributing, you agree your contribution is licensed under the
project's license, GPLv3 or later (see `LICENSE`).

## Ground rules

These aren't style preferences — they're the reasons this app is safe to
put health data in, so PRs that violate them will be asked to change
regardless of how the rest of the code looks:

- **No network calls, ever.** No HTTP clients, no analytics/telemetry SDKs,
  no crash reporters that phone home. The pre-commit hook scans for network
  URLs in Dart files and will fail your commit if it finds one — see
  `.url-scan-ignore` if you have a genuine, justified exception.
- **The database stays encrypted.** Don't touch `lib/data/database/` or
  `lib/core/security/` without reading "Encrypted, biometric-gated storage"
  in `CLAUDE.md` first — there's a real history of subtly-broken PRs in this
  exact area (a biometric-gate bypass, a silent auto-retry bug), and the
  reasoning there explains why the current code looks the way it does.
- **Exported backups from older versions must still import cleanly.** Any
  schema change needs a migration (see "Adding/Changing a Database Table"
  in `CLAUDE.md`), not a breaking change to the existing shape.

## Getting set up

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
./scripts/setup_git_hooks.sh   # installs pre-commit (format/analyze/URL-scan) and pre-push (test)
flutter run
```

See `README.md` for simulator/emulator setup and known platform quirks
(macOS Keychain friction in particular — it's expected, not a bug), and
`CLAUDE.md` for the full architecture and conventions reference.

## Workflow

This project develops feature-first, spec-first:

1. **Specify the behavior** as Gherkin scenarios in `docs/features/*.feature`
   (add to an existing file or create one — see the table in `CLAUDE.md`).
2. **Write failing tests** implementing those scenarios.
3. **Implement** in `lib/`, following the existing feature-first structure
   (`lib/features/<feature>/`, providers in `lib/core/providers/`,
   repositories in `lib/data/repositories/`, domain models in `lib/models/`).
4. **Validate**: `flutter analyze` (zero issues), `dart format --set-exit-if-changed .`,
   `flutter test`.

Cycle-math logic (prediction/statistics) is pure, dependency-free, and
exhaustively unit-tested — if you're touching anything in
`test/unit/cycle_math/`, that bar applies to your change too, including
edge cases like irregular cycles, gaps in logging, and DST boundaries.

## Before opening a PR

- `flutter analyze` passes with zero warnings/errors.
- `dart format --set-exit-if-changed .` — no formatting diffs.
- `flutter test` passes locally (the pre-push hook runs this automatically
  unless you've bypassed it).
- New/changed behavior has a corresponding `.feature` scenario and test
  coverage, per the workflow above.
- Database schema changes include a migration and an updated export/import
  path (see "Adding/Changing a Database Table" in `CLAUDE.md`).

CI runs the same format/analyze/URL-scan checks plus the full test suite
with coverage on every PR — it needs to be green before merge.

## Commit / PR conventions

- Keep commits focused; a clear message beats a long diff explaining itself.
- Open PRs against `main`. Small, reviewable PRs are much easier to land
  than large ones, especially anything near the encryption/security code.
- Link the `docs/features/*.feature` scenario(s) your change implements or
  affects, where relevant.

## Reporting bugs / requesting features

Open a GitHub issue. For anything that looks like a security or privacy
issue specifically (e.g. a way data could leave the device, or a way the
encrypted database or biometric gate could be bypassed), please don't file
a public issue — email development@automatedbytes.com directly so it can be fixed
before it's public.

## Code of Conduct

This project follows the [Contributor Covenant](CODE_OF_CONDUCT.md). By
participating, you're expected to uphold it.
