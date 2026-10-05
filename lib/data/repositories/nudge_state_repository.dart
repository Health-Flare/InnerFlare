import 'package:inner_flare/core/nudges/nudge_rules.dart';
import 'package:inner_flare/data/database/schema.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Hand-written SQL access to `nudge_states`: the user's dismiss/snooze
/// choice for each dashboard nudge (docs/features/dashboard_nudges.feature).
/// Keyed by a plain string so this layer doesn't know which nudges exist;
/// `DashboardNudge.storageKey` supplies the keys. Never included in backups.
class NudgeStateRepository {
  NudgeStateRepository(this._db);

  final Database _db;

  /// Every stored choice, by nudge id. A nudge with no entry has never
  /// been dismissed or snoozed.
  Future<Map<String, NudgeState>> getAll() async {
    final rows = await _db.query(nudgeStatesTable);
    final result = <String, NudgeState>{};
    for (final row in rows) {
      final disposition = NudgeDisposition.values
          .asNameMap()[row['disposition']];
      // A value from a newer app version this one doesn't know: skip it
      // rather than crash, so the nudge simply shows.
      if (disposition == null) continue;
      final rawUntil = row['snoozed_until'] as String?;
      final until = rawUntil == null ? null : DateTime.parse(rawUntil);
      if (disposition == NudgeDisposition.snoozed && until == null) continue;
      result[row['nudge_id'] as String] = NudgeState(
        disposition: disposition,
        snoozedUntil: until,
      );
    }
    return result;
  }

  /// Stores [state] for [nudgeId], replacing any earlier choice.
  Future<void> save(String nudgeId, NudgeState state) async {
    await _db.insert(nudgeStatesTable, {
      'nudge_id': nudgeId,
      'disposition': state.disposition.name,
      'snoozed_until': state.snoozedUntil?.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Ends every "until a card is added" snooze. Called whenever the user
  /// adds a dashboard card ("Snoozing a cleanup nudge re-surfaces it the
  /// next time a card is added"). Date-based snoozes and dismissals stay.
  Future<void> endCardAddedSnoozes() async {
    await _db.delete(
      nudgeStatesTable,
      where: 'disposition = ?',
      whereArgs: [NudgeDisposition.snoozedUntilCardAdded.name],
    );
  }

  /// Debug only ("End snoozes now"): ends every snooze, keeps dismissals.
  Future<void> endAllSnoozes() async {
    await _db.delete(
      nudgeStatesTable,
      where: 'disposition != ?',
      whereArgs: [NudgeDisposition.dismissedPermanently.name],
    );
  }

  /// Debug only ("Reset all nudges"): back to a fresh install.
  Future<void> deleteAll() async {
    await _db.delete(nudgeStatesTable);
  }
}
