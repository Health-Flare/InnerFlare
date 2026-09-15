import 'package:inner_flare/models/cycle_day_log.dart';
import 'package:inner_flare/models/ovulation_test_result.dart';
import 'package:inner_flare/models/period_flow.dart';
import 'package:inner_flare/models/tracked_symptom.dart';

/// The portable contents of an export/import backup file
/// (docs/features/export.feature). Deliberately narrower than the whole
/// database: `dashboard_card_preferences`, `quick_stat_preferences`, and
/// `security_settings` are per-device settings that never round-trip
/// through a backup — see design decision 3 in export.feature. Only
/// `cycle_day_logs` and the `symptoms` catalog (needed to make sense of the
/// symptom ids a log references) travel with the data.
class BackupData {
  const BackupData({
    required this.schemaVersion,
    required this.exportedAt,
    required this.cycleDayLogs,
    required this.symptoms,
  });

  /// The exporting app's `schema_version` at the time of export
  /// (lib/data/database/schema.dart) — not this envelope's own format
  /// version, which lives one level up in [BackupFile].
  final int schemaVersion;
  final DateTime exportedAt;
  final List<CycleDayLog> cycleDayLogs;

  /// Empty for a backup exported before the symptom catalog existed
  /// (schema_version < 5) — importing one of those falls back to whatever
  /// built-in symptoms are already seeded on the importing device, since
  /// their ids are fixed forever (see builtInSymptoms in
  /// lib/models/tracked_symptom.dart).
  final List<TrackedSymptom> symptoms;

  Map<String, Object?> toJson() {
    return {
      'schema_version': schemaVersion,
      'exported_at': exportedAt.toIso8601String(),
      'cycle_day_logs': cycleDayLogs.map(_logToJson).toList(),
      'symptoms': symptoms.map(_symptomToJson).toList(),
    };
  }

  /// Throws [FormatException] for anything that isn't at least a
  /// recognizable backup shape — the caller (BackupImporter) is
  /// responsible for turning that into the user-facing "not a valid
  /// export" rejection (docs/features/export.feature).
  static BackupData fromJson(Map<String, Object?> json) {
    final schemaVersion = json['schema_version'];
    final exportedAt = json['exported_at'];
    final cycleDayLogs = json['cycle_day_logs'];
    if (schemaVersion is! int ||
        exportedAt is! String ||
        cycleDayLogs is! List) {
      throw const FormatException('Not a recognizable Inner Flare backup.');
    }

    // Missing entirely (schema_version < 5, before this table existed) is
    // fine and yields no symptoms; present-but-wrong-shaped is not.
    final symptomsJson = json['symptoms'];
    if (symptomsJson != null && symptomsJson is! List) {
      throw const FormatException('Not a recognizable Inner Flare backup.');
    }

    final symptomsList = symptomsJson is List
        ? symptomsJson
        : const <Object?>[];

    return BackupData(
      schemaVersion: schemaVersion,
      exportedAt: DateTime.parse(exportedAt),
      cycleDayLogs: cycleDayLogs
          .cast<Map<String, Object?>>()
          .map(_logFromJson)
          .toList(),
      symptoms: symptomsList
          .cast<Map<String, Object?>>()
          .map(_symptomFromJson)
          .toList(),
    );
  }

  static Map<String, Object?> _logToJson(CycleDayLog log) {
    return {
      'date': _dateKey(log.date),
      'period_flow': log.periodFlow?.name,
      'is_period_start': log.isPeriodStart,
      'symptoms': log.symptoms.toList(),
      'note': log.note,
      'ovulation_test_result': log.ovulationTestResult?.name,
      'basal_body_temp_celsius': log.basalBodyTempCelsius,
    };
  }

  static CycleDayLog _logFromJson(Map<String, Object?> json) {
    final symptoms = json['symptoms'];
    return CycleDayLog(
      date: _parseDateKey(json['date'] as String),
      periodFlow: _enumOrNull(
        PeriodFlow.values,
        json['period_flow'] as String?,
      ),
      isPeriodStart: json['is_period_start'] as bool? ?? false,
      symptoms: symptoms is List ? symptoms.cast<String>().toSet() : const {},
      note: json['note'] as String?,
      ovulationTestResult: _enumOrNull(
        OvulationTestResult.values,
        json['ovulation_test_result'] as String?,
      ),
      basalBodyTempCelsius: (json['basal_body_temp_celsius'] as num?)
          ?.toDouble(),
    );
  }

  static Map<String, Object?> _symptomToJson(TrackedSymptom symptom) {
    return {
      'id': symptom.id,
      'label': symptom.label,
      'is_custom': symptom.isCustom,
      'enabled': symptom.enabled,
      'sort_order': symptom.sortOrder,
    };
  }

  static TrackedSymptom _symptomFromJson(Map<String, Object?> json) {
    return TrackedSymptom(
      id: json['id'] as String,
      label: json['label'] as String,
      isCustom: json['is_custom'] as bool? ?? false,
      enabled: json['enabled'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  static String _dateKey(DateTime date) {
    final dateOnly = DateTime.utc(date.year, date.month, date.day);
    return dateOnly.toIso8601String().split('T').first;
  }

  /// Parses a `YYYY-MM-DD` key back into a UTC-midnight [DateTime] —
  /// `DateTime.parse` alone would interpret a bare date as *local*
  /// midnight, which is a different instant on every device not in UTC
  /// and contradicts [CycleDayLog.date]'s own "date-only (UTC midnight)"
  /// invariant.
  static DateTime _parseDateKey(String key) {
    final parts = key.split('-');
    return DateTime.utc(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  static T? _enumOrNull<T extends Enum>(List<T> values, String? name) {
    if (name == null) return null;
    for (final value in values) {
      if (value.name == name) return value;
    }
    // An unrecognized enum value (e.g. a future app version's new
    // PeriodFlow entry, imported on an older one) is dropped for that
    // field rather than rejecting the whole import.
    return null;
  }
}
