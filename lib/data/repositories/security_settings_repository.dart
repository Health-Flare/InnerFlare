import 'package:inner_flare/data/database/schema.dart';
import 'package:inner_flare/models/lock_timeout.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Hand-written SQL access to `security_settings`: the idle-lock timeout
/// (docs/features/app_lock.feature) and whether the first-run disclaimer
/// has been acknowledged (docs/features/first_run_disclaimer.feature).
/// A single-row table: there's one setting per device, not per-record.
/// Neither value is included in backups.
class SecuritySettingsRepository {
  SecuritySettingsRepository(this._db);

  final Database _db;

  /// The saved idle-lock timeout, or [LockTimeout.defaultValue] if
  /// nothing has been saved yet (first run, before the user visits
  /// Settings).
  Future<LockTimeout> getLockTimeout() async {
    final rows = await _db.query(securitySettingsTable, limit: 1);
    if (rows.isEmpty) return LockTimeout.defaultValue;
    return LockTimeout.fromStoredMinutes(
      rows.first['lock_timeout_minutes'] as int?,
    );
  }

  /// Writes only the timeout. An existing disclaimer acknowledgement is
  /// left as-is: `INSERT OR REPLACE` would delete the row and reset that
  /// flag to its default.
  Future<void> setLockTimeout(LockTimeout timeout) async {
    await _db.execute(
      '''
      INSERT INTO $securitySettingsTable (
        id, lock_timeout_minutes, disclaimer_acknowledged
      )
      VALUES (?, ?, 0)
      ON CONFLICT(id) DO UPDATE SET
        lock_timeout_minutes = excluded.lock_timeout_minutes
      ''',
      [0, timeout.storedMinutes],
    );
  }

  /// False when no row has been saved yet, which is the first launch.
  Future<bool> getDisclaimerAcknowledged() async {
    final rows = await _db.query(
      securitySettingsTable,
      columns: const ['disclaimer_acknowledged'],
      limit: 1,
    );
    if (rows.isEmpty) return false;
    final stored = rows.first['disclaimer_acknowledged'] as int? ?? 0;
    return stored != 0;
  }

  /// Records that the user continued past the first-run disclaimer.
  ///
  /// A brand-new row also stores [LockTimeout.defaultValue]. NULL
  /// `lock_timeout_minutes` means "Never", so inserting the flag alone
  /// would silently change the timeout away from its documented default.
  /// An existing timeout is left untouched.
  Future<void> setDisclaimerAcknowledged() async {
    await _db.execute(
      '''
      INSERT INTO $securitySettingsTable (
        id, lock_timeout_minutes, disclaimer_acknowledged
      )
      VALUES (?, ?, 1)
      ON CONFLICT(id) DO UPDATE SET
        disclaimer_acknowledged = excluded.disclaimer_acknowledged
      ''',
      [0, LockTimeout.defaultValue.storedMinutes],
    );
  }
}
