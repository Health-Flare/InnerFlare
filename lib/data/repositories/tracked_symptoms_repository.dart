import 'package:inner_flare/data/database/schema.dart';
import 'package:inner_flare/models/tracked_symptom.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Hand-written SQL access to `symptoms`
/// (docs/features/symptom_settings.feature). Maps rows to/from
/// [TrackedSymptom]; providers call this, never raw SQL directly.
class TrackedSymptomsRepository {
  TrackedSymptomsRepository(this._db);

  final Database _db;

  Future<List<TrackedSymptom>> getAll() async {
    final rows = await _db.query(symptomsTable, orderBy: 'sort_order ASC');
    return rows.map(_fromRow).toList();
  }

  /// Adds a new custom symptom, enabled by default, at the end of the
  /// list.
  Future<TrackedSymptom> add(String label) async {
    final maxOrderRows = await _db.rawQuery(
      'SELECT MAX(sort_order) AS max_order FROM $symptomsTable',
    );
    final maxOrder = maxOrderRows.first['max_order'] as int?;
    final symptom = TrackedSymptom(
      id: 'custom_${DateTime.now().microsecondsSinceEpoch}',
      label: label,
      isCustom: true,
      enabled: true,
      sortOrder: (maxOrder ?? -1) + 1,
    );
    await _db.insert(symptomsTable, _toRow(symptom));
    return symptom;
  }

  /// Renames [id]'s label — the only field a built-in symptom's row can
  /// change; its `id` and `is_custom` are fixed forever.
  Future<void> rename(String id, String label) async {
    await _db.update(
      symptomsTable,
      {'label': label},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Flips whether [id] appears as a chip on the log screen. Never
  /// deletes the row or touches any day already logged with it.
  Future<void> setEnabled(String id, bool enabled) async {
    await _db.update(
      symptomsTable,
      {'enabled': enabled ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Map<String, Object?> _toRow(TrackedSymptom symptom) {
    return {
      'id': symptom.id,
      'label': symptom.label,
      'is_custom': symptom.isCustom ? 1 : 0,
      'enabled': symptom.enabled ? 1 : 0,
      'sort_order': symptom.sortOrder,
    };
  }

  TrackedSymptom _fromRow(Map<String, Object?> row) {
    return TrackedSymptom(
      id: row['id'] as String,
      label: row['label'] as String,
      isCustom: (row['is_custom'] as int) == 1,
      enabled: (row['enabled'] as int) == 1,
      sortOrder: row['sort_order'] as int,
    );
  }
}
