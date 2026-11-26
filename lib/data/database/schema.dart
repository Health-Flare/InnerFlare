import 'dart:convert';

import 'package:inner_flare/models/lock_timeout.dart';
import 'package:inner_flare/models/quick_stat.dart';
import 'package:inner_flare/models/tracked_symptom.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Bumped whenever the schema changes; every bump needs a matching branch
/// in [onUpgrade] so exported backups from older versions still import
/// cleanly (see BRIEF.md §4.2).
const int schemaVersion = 10;

const String cycleDayLogsTable = 'cycle_day_logs';

const String _createCycleDayLogsTable =
    '''
CREATE TABLE $cycleDayLogsTable (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  date TEXT NOT NULL UNIQUE,
  period_flow TEXT,
  is_period_start INTEGER NOT NULL DEFAULT 0,
  symptoms TEXT NOT NULL DEFAULT '',
  note TEXT,
  ovulation_test_result TEXT,
  basal_body_temp_celsius REAL,
  period_day_override INTEGER
)
''';

/// Per-device dashboard card show/hide + order + mode config
/// (docs/features/dashboard.feature, docs/features/dashboard_visualizations
/// .feature). Never synced: see "Card preferences are stored per-device
/// in settings, not synced".
///
/// `card_id` is the per-*instance* identity, not the card kind: calendar
/// and insights are singletons whose `card_id` equals their kind name
/// (unchanged since schema_version 2, so existing rows still resolve),
/// but a gauge/trend card's `card_id` is generated when it's added via
/// the add-card flow, since a user can add more than one card of the same
/// kind. `card_kind` is the `DashboardCardKind` enum name; `config` is an
/// opaque JSON-encoded string map (see [DashboardCardInstance.config]),
/// NULL for calendar/insights.
const String dashboardCardPreferencesTable = 'dashboard_card_preferences';

const String _createDashboardCardPreferencesTable =
    '''
CREATE TABLE $dashboardCardPreferencesTable (
  card_id TEXT PRIMARY KEY,
  card_kind TEXT NOT NULL,
  visible INTEGER NOT NULL DEFAULT 1,
  sort_order INTEGER NOT NULL,
  config TEXT
)
''';

/// Per-device security and first-run settings
/// (docs/features/app_lock.feature, docs/features/first_run_disclaimer.feature).
/// A single-row table (the `id = 0` check makes it a true singleton)
/// since there's one setting per device, not per-record. Never exported:
/// see export.feature design decision 3.
///
/// `lock_timeout_minutes` is NULL for the "Never" choice, otherwise the
/// number of minutes backgrounded before the app re-locks.
/// `disclaimer_acknowledged` is 1 once the user has continued past the
/// first-run privacy and not-a-medical-device statement.
const String securitySettingsTable = 'security_settings';

const String _createSecuritySettingsTable =
    '''
CREATE TABLE $securitySettingsTable (
  id INTEGER PRIMARY KEY CHECK (id = 0),
  lock_timeout_minutes INTEGER,
  disclaimer_acknowledged INTEGER NOT NULL DEFAULT 0
)
''';

/// Legacy home of quick stat configuration, pre-schema_version 7. No
/// longer written to: quick stats are `dashboard_card_preferences` rows
/// like every other card now (docs/features/dashboard_grid_layout
/// .feature), migrated onto that shape once, in [onUpgrade]'s
/// `oldVersion < 7` branch. Table (and its create statement) kept only so
/// that branch has something to read from on an existing install.
const String quickStatPreferencesTable = 'quick_stat_preferences';

const String _createQuickStatPreferencesTable =
    '''
CREATE TABLE $quickStatPreferencesTable (
  slot INTEGER PRIMARY KEY,
  stat_type TEXT NOT NULL,
  reference_point TEXT NOT NULL
)
''';

/// The user's configurable symptom catalog (docs/features/symptom_settings.
/// feature): built-in defaults plus anything they've added, each with its
/// own enabled state. `cycle_day_logs.symptoms` stores a comma-separated
/// list of `id`s from this table.
const String symptomsTable = 'symptoms';

const String _createSymptomsTable =
    '''
CREATE TABLE $symptomsTable (
  id TEXT PRIMARY KEY,
  label TEXT NOT NULL,
  is_custom INTEGER NOT NULL DEFAULT 0,
  enabled INTEGER NOT NULL DEFAULT 1,
  sort_order INTEGER NOT NULL
)
''';

Future<void> _seedBuiltInSymptoms(Database db) async {
  for (var i = 0; i < builtInSymptoms.length; i++) {
    final (id, label) = builtInSymptoms[i];
    await db.insert(symptomsTable, {
      'id': id,
      'label': label,
      'is_custom': 0,
      'enabled': 1,
      'sort_order': i,
    });
  }
}

Future<void> onCreate(Database db, int version) async {
  await db.execute(_createCycleDayLogsTable);
  await db.execute(_createDashboardCardPreferencesTable);
  await db.execute(_createSecuritySettingsTable);
  await db.execute(_createQuickStatPreferencesTable);
  await db.execute(_createSymptomsTable);
  await _seedBuiltInSymptoms(db);
}

/// Bump [schemaVersion] and add a branch here (keyed off [oldVersion])
/// every time the shape of a shipped table changes.
Future<void> onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    await db.execute(_createDashboardCardPreferencesTable);
  }
  if (oldVersion < 3) {
    await db.execute(_createSecuritySettingsTable);
  }
  if (oldVersion < 4) {
    await db.execute(_createQuickStatPreferencesTable);
  }
  if (oldVersion < 5) {
    await db.execute(_createSymptomsTable);
    await _seedBuiltInSymptoms(db);
  }
  if (oldVersion >= 2 && oldVersion < 6) {
    // oldVersion < 2 already creates the table via the current (post-v6)
    // _createDashboardCardPreferencesTable above, so only versions that
    // created the table in its pre-v6 shape need the ALTERs below.
    //
    // Pre-existing rows only ever had card_id == the card's kind (calendar
    // or insights, the only kinds that existed before gauge/trend cards),
    // so backfilling card_kind from card_id is exact, not a guess.
    await db.execute(
      'ALTER TABLE $dashboardCardPreferencesTable '
      "ADD COLUMN card_kind TEXT NOT NULL DEFAULT ''",
    );
    await db.execute(
      'ALTER TABLE $dashboardCardPreferencesTable ADD COLUMN config TEXT',
    );
    await db.execute(
      'UPDATE $dashboardCardPreferencesTable SET card_kind = card_id',
    );
  }
  if (oldVersion < 7) {
    // Fold the old fixed two-slot quick_stat_preferences table into
    // dashboard_card_preferences as `quickStat`-kind rows, so quick
    // stats become part of the same reorderable grid as every other
    // card instead of a separate, always-two-slots row (docs/features/
    // dashboard_grid_layout.feature). Mirrors
    // QuickStatPreferencesRepository.getAll()'s old "merge saved rows
    // with the documented defaults per slot" behavior, so an install
    // that never touched customization still gets the same two cards a
    // fresh install would.
    final savedBySlot = {
      for (final row in await db.query(
        quickStatPreferencesTable,
        orderBy: 'slot ASC',
      ))
        row['slot'] as int: row,
    };
    const defaultTypeBySlot = {
      0: QuickStatType.daysSinceLastPeriod,
      1: QuickStatType.estimatedDaysToNextPeriod,
    };

    // Make room at the front of the order for the two migrated quick
    // stat cards: matches where quick stats have always appeared, just
    // above Calendar/Insights/whatever else is already there.
    await db.execute(
      'UPDATE $dashboardCardPreferencesTable SET sort_order = sort_order + 2',
    );

    for (final slot in [0, 1]) {
      final saved = savedBySlot[slot];
      final statType = saved == null
          ? defaultTypeBySlot[slot]!
          : QuickStatType.values.byName(saved['stat_type'] as String);
      final referencePoint = saved == null
          ? QuickStatReferencePoint.periodEnd
          : QuickStatReferencePoint.values.byName(
              saved['reference_point'] as String,
            );
      await db.insert(dashboardCardPreferencesTable, {
        'card_id': 'quick-stat-$slot',
        'card_kind': 'quickStat',
        'visible': 1,
        'sort_order': slot,
        'config': jsonEncode({
          'quick_stat_type': statType.name,
          'quick_stat_reference_point': referencePoint.name,
        }),
      });
    }
  }
  if (oldVersion < 8) {
    await _addDisclaimerAcknowledgedColumn(db);
  }
  if (oldVersion < 9) {
    await _addPeriodDayOverrideColumn(db);
  }
  if (oldVersion < 10) {
    await _moveOldDefaultLockTimeout(db);
  }
}

/// Issue #90: the default idle-lock timeout went from 15 minutes to 1.
///
/// Up to schema 9, accepting the first-run statement saved the default
/// (15) into `lock_timeout_minutes`, so a saved 15 can't be told apart
/// from someone who never opened Auto-lock. Treat it as never chosen and
/// move it to the new default; every other saved value (including NULL,
/// which means "Never") was a real choice and is left alone. Someone who
/// really wanted 15 can pick it again, and it sticks from then on.
/// Skipped if the table is missing (partial test fixtures).
Future<void> _moveOldDefaultLockTimeout(Database db) async {
  final tables = await db.rawQuery(
    "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = ?",
    [securitySettingsTable],
  );
  if (tables.isEmpty) return;

  await db.update(
    securitySettingsTable,
    {'lock_timeout_minutes': LockTimeout.defaultValue.storedMinutes},
    where: 'lock_timeout_minutes = ?',
    whereArgs: [15],
  );
}

/// Adds [cycle_day_logs.period_day_override] (issue #103): the user's own
/// "Period day" choice, 1 / 0, or NULL for "work it out from flow". Every
/// existing row gets NULL, so nothing changes until the user makes a
/// choice. Skipped if the table is missing (partial test fixtures) or
/// already has the column.
Future<void> _addPeriodDayOverrideColumn(Database db) async {
  final tables = await db.rawQuery(
    "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = ?",
    [cycleDayLogsTable],
  );
  if (tables.isEmpty) return;

  final columns = await db.rawQuery('PRAGMA table_info($cycleDayLogsTable)');
  if (columns.any((column) => column['name'] == 'period_day_override')) {
    return;
  }

  await db.execute(
    'ALTER TABLE $cycleDayLogsTable ADD COLUMN period_day_override INTEGER',
  );
}

/// Adds [security_settings.disclaimer_acknowledged] for installs that
/// already have the pre-v8 table. Fresh installs and upgrades from
/// before the table existed create it via [_createSecuritySettingsTable],
/// which already includes the column. A partial fixture that calls
/// [onUpgrade] without ever creating `security_settings` (see the
/// schema-5 dashboard migration test) is left alone.
Future<void> _addDisclaimerAcknowledgedColumn(Database db) async {
  final tables = await db.rawQuery(
    "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = ?",
    [securitySettingsTable],
  );
  if (tables.isEmpty) return;

  final columns = await db.rawQuery(
    'PRAGMA table_info($securitySettingsTable)',
  );
  final hasColumn = columns.any(
    (column) => column['name'] == 'disclaimer_acknowledged',
  );
  if (hasColumn) return;

  await db.execute(
    'ALTER TABLE $securitySettingsTable '
    'ADD COLUMN disclaimer_acknowledged INTEGER NOT NULL DEFAULT 0',
  );
}
