import 'package:inner_flare/data/database/schema.dart';
import 'package:inner_flare/models/quick_stat.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// The two default quick stat slots, used until the user customizes them
/// — see docs/features/quick_stats.feature, "Default first/second quick
/// stat".
const List<QuickStatPreference> defaultQuickStatPreferences = [
  QuickStatPreference(slot: 0, type: QuickStatType.daysSinceLastPeriod),
  QuickStatPreference(slot: 1, type: QuickStatType.estimatedDaysToNextPeriod),
];

/// Hand-written SQL access to `quick_stat_preferences`. Maps rows to/from
/// [QuickStatPreference]; providers call this, never raw SQL directly.
class QuickStatPreferencesRepository {
  QuickStatPreferencesRepository(this._db);

  final Database _db;

  /// Both slots, merging saved rows with [defaultQuickStatPreferences] for
  /// any slot not yet saved — so a freshly-installed app (or a slot never
  /// touched in customization) still renders the documented defaults.
  Future<List<QuickStatPreference>> getAll() async {
    final rows = await _db.query(quickStatPreferencesTable);
    final saved = <int, QuickStatPreference>{
      for (final row in rows)
        row['slot'] as int: QuickStatPreference(
          slot: row['slot'] as int,
          type: QuickStatType.values.byName(row['stat_type'] as String),
          referencePoint: QuickStatReferencePoint.values.byName(
            row['reference_point'] as String,
          ),
        ),
    };

    return [
      for (final fallback in defaultQuickStatPreferences)
        saved[fallback.slot] ?? fallback,
    ];
  }

  /// Replaces [slot]'s saved configuration with [preference].
  Future<void> save(QuickStatPreference preference) async {
    await _db.insert(quickStatPreferencesTable, {
      'slot': preference.slot,
      'stat_type': preference.type.name,
      'reference_point': preference.referencePoint.name,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
