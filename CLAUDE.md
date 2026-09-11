# Claude Code Project Guide — Inner Flare

Inner Flare is a menstrual cycle tracking companion for iOS and Android. It's built with Flutter, uses Riverpod for state management, SQLite for local storage, and follows a feature-first architecture. The app is **fully offline** — no network calls, no cloud sync, all data stays on device unless the user explicitly exports it.

The database is encrypted at rest with SQLCipher (`sqflite_sqlcipher`, same API as `sqflite`), not plain `sqflite` — see "Encrypted, biometric-gated storage" under Key Design Decisions before touching `lib/data/database/` or `lib/core/security/`.

See `BRIEF.md` for the product/technical brief this project started from — note that BRIEF.md §4.1 recommends plain `sqflite`; the encryption layer was added afterward as an explicit privacy requirement and supersedes that recommendation.

> **Status:** scaffolded (`pubspec.yaml`, `lib/`, `test/` all exist). The structure and workflow below describe the current shape of the project, not just a target.

## Quick Start Commands

```bash
# One-time: install git hooks (pre-commit: format/analyze/URL-scan, pre-push: test)
./scripts/setup_git_hooks.sh

# Run the app
flutter run

# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Analyze code (must pass with zero issues)
flutter analyze

# Format code
dart format .

# Generate Riverpod code
dart run build_runner build --delete-conflicting-outputs
```

There is no separate database codegen step — storage is hand-written SQL and hand-written migrations against an encrypted SQLite file (`sqflite_sqlcipher`, a drop-in `sqflite` fork). Do not add an ORM or database code generator without updating this file and confirming it doesn't conflict with `riverpod_generator`'s `build_runner` step.

## Project Architecture

```
lib/
├── core/
│   ├── providers/      # Riverpod providers (state management)
│   ├── router/         # go_router configuration
│   ├── security/        # Encryption passphrase store, biometric gate, backup exclusion
│   └── theme/          # Colors, typography, theming
├── data/
│   ├── database/        # Encrypted sqflite_sqlcipher setup, schema, migrations (schema_version tracked)
│   └── repositories/     # Hand-written SQL query/repository classes
├── features/            # Feature-first organization
│   ├── dashboard/        # Customizable card layout: show/hide/reorder
│   ├── log/              # Quick daily logging (period flow, symptoms, note)
│   ├── calendar/          # Calendar + history view
│   ├── insights/          # Cycle length/variability/prediction stats
│   ├── export/            # Backup export/import
│   ├── onboarding/
│   └── settings/
└── models/               # Domain models (immutable, non-DB)

docs/
└── features/             # BDD feature files (Gherkin scenarios)

BRIEF.md                  # Product/technical brief (repo root)
test/                     # Unit and widget tests
integration_test/         # E2E tests
```

## Development Workflow

### Feature File → Test → Code → Validation

1. **Specify behavior** in `docs/features/*.feature` (Gherkin format)
2. **Write failing tests** that implement the scenarios
3. **Implement the feature** in `lib/`
4. **Validate** by running tests and ensuring they pass

Cycle-math logic (average cycle length, variability, next-period/fertile-window prediction) lives as **pure functions** with no Flutter/DB dependency, so it can be unit-tested exhaustively — this is the highest-value test surface in the app. Cover: first-ever cycle with no history, irregular cycles, gaps in logging, and date/timezone edge cases (DST boundaries).

### Feature Files

| Feature | File |
|---------|------|
| Onboarding | `docs/features/onboarding.feature` |
| Daily logging | `docs/features/log.feature` |
| Calendar/history | `docs/features/calendar.feature` |
| Cycle insights/predictions | `docs/features/insights.feature` |
| Dashboard customization | `docs/features/dashboard.feature` |
| Export/import | `docs/features/export.feature` |
| Navigation | `docs/features/navigation.feature` |

## Code Patterns

### Domain Models vs Database Rows

- Domain models in `lib/models/` are immutable and used in business logic.
- `lib/data/database/` holds raw schema + migrations; `lib/data/repositories/` holds hand-written queries that map rows to/from domain models.
- Providers call repositories, never raw SQL directly.

```dart
// Domain model (lib/models/cycle_day_log.dart)
class CycleDayLog {
  final DateTime date;
  final PeriodFlow? flow;
  final Set<Symptom> symptoms;
  final String? note;
  // ...
}
```

### Riverpod Providers

```dart
@riverpod
class CycleLogNotifier extends _$CycleLogNotifier {
  @override
  Future<List<CycleDayLog>> build() async {
    // Load via repository, not raw SQL
  }
}
```

### Database Migrations

Every schema change needs a migration step keyed off `schema_version` in `onUpgrade`. Never alter a shipped table's shape without a migration — exported backups from older versions must still import cleanly (see `BRIEF.md` §4.2).

## Testing

```
test/
├── unit/
│   ├── cycle_math/     # Pure prediction/statistics logic — exhaustive edge cases
│   └── providers/       # Provider unit tests
├── widget/               # Widget tests
├── helpers/              # Test utilities (TestDatabase, TestAppBuilder)
└── fixtures/              # Test data factories
```

```bash
flutter test
flutter test --coverage
flutter test test/widget/log_screen_test.dart
```

Use `pump(Duration(milliseconds: 500))` instead of `pumpAndSettle()` when providers are loading asynchronously.

## CI/CD & Git Hooks

- **Git hooks** (`.githooks/`, enabled via `./scripts/setup_git_hooks.sh`):
  `pre-commit` runs `dart format --set-exit-if-changed`, `flutter analyze`,
  and the offline-URL scan; `pre-push` runs `flutter test`. Skip either with
  `--no-verify` when you know what you're doing.
- **CI** (`.github/workflows/ci.yml`): the same format/analyze/URL-scan
  checks plus `flutter test --coverage`, on every push to `main` and every
  PR.
- **Android build & release** (`.github/workflows/android-release.yml`):
  a debug APK builds only on manual dispatch (Actions tab → "Run workflow"),
  for sideloading during development — it no longer builds automatically on
  push to `main`. Pushing a `v*.*.*` tag builds a signed
  release App Bundle + APK and attaches them to a GitHub Release — see
  `docs/deployment/android-release.md` for the one-time keystore/secrets
  setup and the pre-launch Play Store checklist.
- **iOS build & release** (`.github/workflows/ios-release.yml`): an unsigned
  iOS Simulator build on manual dispatch, no signing setup needed — a
  smoke test, not something installable on a device. Pushing a `v*.*.*`
  tag builds a signed IPA and uploads it to App Store Connect — see
  `docs/deployment/ios-release.md` for the one-time Apple Developer/App
  Store Connect setup, the repo secrets it needs, and the pre-launch App
  Store checklist. As of writing this job can't actually run to completion
  yet — the Apple secrets it depends on haven't been created.
- **F-Droid**: no CI of ours — see `docs/deployment/fdroid/README.md` and
  `docs/deployment/release-tasklist.md` for the submission plan; F-Droid
  builds from a tagged commit on its own infrastructure via a metadata
  file submitted to `fdroid/fdroid-data`, not a workflow in this repo.
- **Dependency updates** (`renovate.json5`): weekly (Monday) batched PRs for
  `pubspec.yaml` and GitHub Actions versions, gated by the same CI checks as
  any other PR. Patch/minor dev-only tooling and GitHub Actions bumps
  auto-merge once green; runtime (`dependencies:`) bumps, the riverpod
  family (grouped — it spans `dependencies:`/`dev_dependencies:` and must
  move together), and every major version bump always wait for manual
  review. This split exists because routine-looking bumps have broken the
  build here before (see the biometric-gate and riverpod migration notes
  under "Encrypted, biometric-gated storage") — tune the `packageRules` in
  `renovate.json5` directly if that balance needs to shift.

## Code Quality Rules

### Must Pass

1. `flutter analyze` — zero warnings/errors
2. `dart format --set-exit-if-changed .` — code is formatted
3. No network URLs in Dart files (offline-only app) — flag any exception explicitly in a `.url-scan-ignore` file with a justification comment, same pattern as Health Flare
4. No bundled-fonts-as-network-fetch packages (fonts bundled locally)
5. No cloud/analytics/telemetry SDKs of any kind

### Conventions

- Use `package:<app_name>/` imports, not relative imports
- Single quotes for strings
- Trailing commas for better diffs
- Cancel subscriptions and close sinks
- Cycle-math functions are pure (no `DateTime.now()` calls buried inside — pass "now" in as a parameter so tests are deterministic)

## Common Tasks

### Adding a New Feature

1. Check/create scenarios in `docs/features/<feature>.feature`
2. Create screen in `lib/features/<feature>/screens/`
3. Create widgets in `lib/features/<feature>/widgets/`
4. Add provider in `lib/core/providers/<feature>_provider.dart`
5. Add route in `lib/core/router/app_router.dart`
6. Write tests in `test/widget/<feature>_test.dart`

### Adding/Changing a Database Table

1. Update domain model in `lib/models/<name>.dart`
2. Update schema + add a migration step in `lib/data/database/`
3. Bump `schema_version`
4. Update the repository in `lib/data/repositories/<name>_repository.dart`
5. Update export/import to handle the new/changed shape (backward-compatible import from older schema versions)

### Adding a New Provider

1. Create file `lib/core/providers/<name>_provider.dart`
2. Use `@riverpod` annotation
3. Run `dart run build_runner build --delete-conflicting-outputs`
4. Commit the generated `.g.dart` file

## Key Design Decisions

### Offline-First

- No network permissions
- No analytics or telemetry
- All data stored in a local SQLite file
- Export/import only when the user explicitly requests it, never automatic

### Lightweight by Default

- No ORM, no database code generator — hand-written SQL against a small, stable schema
- Prefer one fewer dependency over one more abstraction; revisit this only if the schema outgrows hand-written queries

### Encrypted, biometric-gated storage

- The SQLite file is encrypted at rest with SQLCipher (`sqflite_sqlcipher`), lives under the app's private support directory (never Documents), and is named to not advertise its contents.
- The passphrase never touches disk — it's generated once and stored only in the platform secure key store (`flutter_secure_storage`: iOS Keychain / Android Keystore-backed prefs). See `lib/core/security/db_passphrase_store.dart`.
- Opening the database is gated behind `local_auth` (Face ID/Touch ID/fingerprint, falling back to device passcode) via `lib/core/security/biometric_gate.dart`. If a device has no biometrics/passcode configured at all, the gate fails open rather than locking the user out — the data is still encrypted regardless. A cancelled, timed-out, or locked-out prompt must fail closed: `local_auth` throws a `LocalAuthException` for those (it does not resolve to `false` the way a plain declined challenge does), so never widen the fail-open `catch` around the capability check to also wrap the `authenticate()` call itself — that was a real bypass, fixed once already.
- The app also re-locks itself behind the same gate after a user-configurable idle timeout (`LockTimeout`, `lib/models/lock_timeout.dart`; defaults to 15 minutes, settable in Settings, persisted in `security_settings.lock_timeout_minutes`) spent backgrounded, regardless of which screen was open — see `lib/core/security/app_lock_gate.dart`, `lib/core/security/background_lock_policy.dart`, and docs/features/app_lock.feature. This is a UI-level lock only: it doesn't close and reopen the SQLCipher connection (there's no passphrase to re-derive from the user), it just covers the app with `AppLockScreen` via `MaterialApp.builder` until re-authenticated.
- `appDatabaseProvider` (`lib/core/providers/database_provider.dart`) sets `retry: _noRetry`. Riverpod 3.x's `ProviderContainer.defaultRetry` otherwise silently retries any provider that throws something other than `Error`/`ProviderException` — up to 10 times, exponential backoff from 200ms to 6.4s. `BiometricAuthenticationFailure implements Exception`, not `Error`, so without opting out, a cancelled or failed unlock would auto-retry `AppDatabase().open()` in the background and re-show the biometric prompt unprompted moments later — a real bug that was live for a while, and exactly the kind of thing that looks like "flaky Android behavior" from the outside. Any new `@riverpod`/`@Riverpod` provider that can throw from a failed unlock (directly or by awaiting `appDatabaseProvider.future`) should get the same `retry: _noRetry` unless silent retrying is actually wanted.
- `DatabaseStatusIndicator` (dashboard AppBar) and the "Database" section in Settings both watch `appDatabaseProvider` directly and show its raw error text plus a manual "Unlock" button — a diagnostic aid while real-device unlock behavior is still being ironed out. Their loading state renders a static icon, never `CircularProgressIndicator`: an indeterminate spinner's animation never lets `WidgetTester.pumpAndSettle` settle, and this state is watched from screens (the dashboard) that plenty of existing widget tests pump without overriding `appDatabaseProvider`.
- `AppLockScreen`'s own re-authentication prompt briefly takes the app through `inactive`/`paused` and back to `resumed` on its own — Face ID's system sheet, or (more so) the separate device-credential activity Android launches for a manual passcode — even though the user never actually left the app. `AppLockGate`'s `WidgetsBindingObserver` is global and couldn't otherwise tell that apart from a real backgrounding, so it recorded the prompt's own transition as time spent away; on a short-enough (or "Immediately") `LockTimeout` this re-locked the app moments after (or even before) that very authentication attempt had unlocked it — every tap of Unlock re-locking itself, permanently, with force-closing the app the only way out. `lib/core/providers/reauthenticating_provider.dart` holds a `keepAlive` flag that `AppLockScreen._unlock()` sets for the duration of its `authenticate()` call; `AppLockGate.didChangeAppLifecycleState` ignores lifecycle transitions entirely while it's set. Deliberately *not* extended to wrap `AppDatabase().open()` in `appDatabaseProvider` too, even though its own initial biometric gate causes the exact same transition: that call can legitimately run for a long time (`persistAcrossBackgrounding: true` lets the prompt sit open indefinitely), and `AppLockGate.build()` watches `lockTimeoutProvider` unconditionally — which chains into `appDatabaseProvider` on every build — so a flag that stuck `true` for that whole window would silently disable idle re-locking app-wide, not just on an already-covered lock screen. Scoping this to `AppLockScreen` is safe because the app is already locked for its entire duration regardless.
- The file is excluded from OS backups: `android:allowBackup="false"` in the Android manifest, and an `isExcludedFromBackup` native call on iOS (`lib/core/security/backup_exclusion.dart` + `ios/Runner/AppDelegate.swift`). The only way data leaves the device is the explicit export feature.
- Android's `MainActivity` is a `FlutterFragmentActivity`, not `FlutterActivity` — `local_auth` requires a fragment host to show its prompt. Don't revert this.

### Privacy-Centric

- No login/account required
- No cloud sync
- Predictions are transparent statistics, not an opaque model — the user can always see what the estimate is based on
- Clear, specific privacy statements (no vague "we value your privacy")
- Not a medical device / no diagnostic claims — state this plainly in onboarding

## Troubleshooting

### sqflite on desktop test runners

If running tests on a non-mobile target (CI, desktop dev), use `sqflite_common_ffi`'s `databaseFactory` override in test setup rather than the platform channel implementation — see `test/helpers/test_database.dart`.

Use `databaseFactoryFfiNoIsolate`, not `databaseFactoryFfi`, in that override. The isolate-backed factory talks to a real background isolate; inside a `testWidgets` test, `pump`/`pumpAndSettle` run in a fake-async zone that never lets that isolate's messages resolve, so the test just hangs with no error. The no-isolate factory runs SQLite on the same isolate and works fine with normal pumping. Plain `test()` bodies (no widget pumping involved) work with either.

Also close every test database explicitly (`tearDown`), even in-memory ones. sqflite caches open databases by path, and every in-memory test database shares the literal `":memory:"` path — an unclosed database from one test is silently reused (rows and all) by the next test's `openDatabase` call.

### macOS: `PlatformException(..., -34018, A required entitlement isn't present., ...)`

`flutter_secure_storage` needs the `keychain-access-groups` entitlement (an empty `<array/>` is enough) in **both** `macos/Runner/DebugProfile.entitlements` and `Release.entitlements` — without it, every Keychain read/write throws this on macOS specifically (`errSecMissingEntitlement`). iOS and Android don't need this for an app's own storage.

Adding that entitlement pulls in a second requirement: macOS enforces it via Keychain Sharing, which needs real local development code signing (a `DEVELOPMENT_TEAM` + resolvable `CODE_SIGN_IDENTITY`, not "Sign to Run Locally"). If your Apple Developer team is an organization account, provisioning also requires this specific Mac to be registered as a device under that team, which needs admin permission on the team — a personal (free) Apple ID team sidesteps that since there's no admin approval step.

Given all of that is macOS-desktop-only friction and this app's shipping targets are iOS and Android (see the top of this file), the current entitlements files deliberately do **not** include `keychain-access-groups` — `flutter run -d macos` builds and runs, but the encrypted database will fail to unlock there with the error above. Test the storage/logging flow on an iOS Simulator or a real iOS/Android device instead; both work without any of this. Only add the macOS entitlement (and matching Xcode signing config) if macOS becomes a real target and you've sorted out signing for it.

### macOS Keychain prompts during local dev

Running the app on macOS desktop (`flutter run -d macos`) will pop a real system Keychain "enter your password to allow access" dialog the first time `flutter_secure_storage` writes the database passphrase — this is macOS-specific behavior tied to ad-hoc/debug code signing identity, not something iOS or Android do for an app's own Keychain/Keystore items. It's expected; don't try to "fix" it as a bug. Never click through it on the user's behalf — it's asking for their real macOS login password.
