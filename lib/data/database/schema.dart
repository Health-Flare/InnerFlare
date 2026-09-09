import 'package:inner_flare/models/tracked_symptom.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Bumped whenever the schema changes; every bump needs a matching branch
/// in [onUpgrade] so exported backups from older versions still import
/// cleanly (see BRIEF.md §4.2).
const int schemaVersion = 4;

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

/// Per-device dashboard card show/hide + order (docs/features/dashboard.
/// feature). Never synced — see "Card preferences are stored per-device
/// in settings, not synced".
const String dashboardCardPreferencesTable = 'dashboard_card_preferences';

const String _createDashboardCardPreferencesTable =
    '''
CREATE TABLE $dashboardCardPreferencesTable (
  card_id TEXT PRIMARY KEY,
  visible INTEGER NOT NULL DEFAULT 1,
  sort_order INTEGER NOT NULL
)
''';

/// Idle-lock timeout setting (docs/features/app_lock.feature). A
/// single-row table — the `id = 0` check makes it a true singleton —
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

/// The user's configurable symptom catalog (docs/features/symptom_settings.
/// feature) — built-in defaults plus anything they've added, each with its
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
    await db.execute(_createSymptomsTable);
    await _seedBuiltInSymptoms(db);
  }
}
