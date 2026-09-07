# Claude Code Project Guide — [App Name TBD]

[App Name] is a menstrual cycle tracking companion for iOS and Android. It's built with Flutter, uses Riverpod for state management, plain SQLite (`sqflite`) for local storage, and follows a feature-first architecture. The app is **fully offline** — no network calls, no cloud sync, all data stays on device unless the user explicitly exports it.

See `BRIEF.md` for the product/technical brief this project started from.

> **Status:** not yet scaffolded — no `pubspec.yaml`, `lib/`, or `test/` exist yet. Everything below (commands, structure, workflow) describes the target shape of the project; treat it as the plan to scaffold *into*, not a description of what's on disk today.

## Quick Start Commands

```bash
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

There is no separate database codegen step — storage is plain `sqflite` with hand-written SQL and hand-written migrations. Do not add an ORM or database code generator without updating this file and confirming it doesn't conflict with `riverpod_generator`'s `build_runner` step.

## Project Architecture

```
lib/
├── core/
│   ├── providers/      # Riverpod providers (state management)
│   ├── router/         # go_router configuration
│   └── theme/          # Colors, typography, theming
├── data/
│   ├── database/        # sqflite setup, schema, migrations (schema_version tracked)
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

### Privacy-Centric

- No login/account required
- No cloud sync
- Predictions are transparent statistics, not an opaque model — the user can always see what the estimate is based on
- Clear, specific privacy statements (no vague "we value your privacy")
- Not a medical device / no diagnostic claims — state this plainly in onboarding

## Troubleshooting

### sqflite on desktop test runners

If running tests on a non-mobile target (CI, desktop dev), use `sqflite_common_ffi`'s `databaseFactory` override in test setup rather than the platform channel implementation.
