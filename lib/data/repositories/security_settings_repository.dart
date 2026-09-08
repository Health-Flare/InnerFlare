import 'package:inner_flare/data/database/schema.dart';
import 'package:inner_flare/models/lock_timeout.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Hand-written SQL access to `security_settings` — currently just the
/// idle-lock timeout (docs/features/app_lock.feature). A single-row
/// table: there's one setting per device, not per-record.
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

  Future<void> setLockTimeout(LockTimeout timeout) async {
    await _db.insert(securitySettingsTable, {
      'id': 0,
      'lock_timeout_minutes': timeout.storedMinutes,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
