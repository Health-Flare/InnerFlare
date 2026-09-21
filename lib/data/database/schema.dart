import 'dart:convert';

import 'package:inner_flare/models/quick_stat.dart';
import 'package:inner_flare/models/tracked_symptom.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Bumped whenever the schema changes; every bump needs a matching branch
/// in [onUpgrade] so exported backups from older versions still import
/// cleanly (see BRIEF.md §4.2).
const int schemaVersion = 7;

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
  basal_body_temp_celsius REAL
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

/// Idle-lock timeout setting (docs/features/app_lock.feature). A
/// single-row table (the `id = 0` check makes it a true singleton)
/// since there's one setting per device, not per-record.
/// `lock_timeout_minutes` is NULL for the "Never" choice, otherwise the
/// number of minutes backgrounded before the app re-locks.
const String securitySettingsTable = 'security_settings';

const String _createSecuritySettingsTable =
    '''
CREATE TABLE $securitySettingsTable (
  id INTEGER PRIMARY KEY CHECK (id = 0),
  lock_timeout_minutes INTEGER
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
}
