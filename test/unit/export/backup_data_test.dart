import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/data/export/backup_data.dart';
import 'package:inner_flare/models/cycle_day_log.dart';
import 'package:inner_flare/models/ovulation_test_result.dart';
import 'package:inner_flare/models/period_flow.dart';
import 'package:inner_flare/models/tracked_symptom.dart';

void main() {
  test('toJson/fromJson round-trips a full log and symptom catalog', () {
    final data = BackupData(
      schemaVersion: 5,
      exportedAt: DateTime.utc(2026, 9, 15, 12),
      cycleDayLogs: [
        CycleDayLog(
          date: DateTime.utc(2026, 9, 1),
          periodFlow: PeriodFlow.medium,
          isPeriodStart: true,
          symptoms: {'cramps', 'fatigue'},
          note: 'felt rough',
          ovulationTestResult: OvulationTestResult.positive,
          basalBodyTempCelsius: 36.7,
        ),
      ],
      symptoms: const [
        TrackedSymptom(
          id: 'cramps',
          label: 'Cramps',
          isCustom: false,
          enabled: true,
          sortOrder: 0,
        ),
        TrackedSymptom(
          id: 'custom_1',
          label: 'Back pain',
          isCustom: true,
          enabled: true,
          sortOrder: 1,
        ),
      ],
    );

    final roundTripped = BackupData.fromJson(data.toJson());

    expect(roundTripped.schemaVersion, 5);
    expect(roundTripped.cycleDayLogs, hasLength(1));
    expect(roundTripped.cycleDayLogs.single, data.cycleDayLogs.single);
    expect(roundTripped.symptoms, data.symptoms);
  });

  test(
    'a backup with no symptoms key (pre-schema-5 export) yields an empty catalog',
    () {
      final json = {
        'schema_version': 4,
        'exported_at': DateTime.utc(2025, 1, 1).toIso8601String(),
        'cycle_day_logs': <Object?>[],
      };

      final data = BackupData.fromJson(json);

      expect(data.symptoms, isEmpty);
    },
  );

  test('a missing required field throws FormatException', () {
    expect(
      () => BackupData.fromJson({'exported_at': '2026-01-01T00:00:00.000Z'}),
      throwsFormatException,
    );
  });

  test(
    'an unrecognized enum value on a log field is dropped, not rejected',
    () {
      final json = {
        'schema_version': 5,
        'exported_at': DateTime.utc(2026, 1, 1).toIso8601String(),
        'cycle_day_logs': [
          {
            'date': '2026-01-01',
            'period_flow': 'torrential', // not a real PeriodFlow value
            'is_period_start': false,
            'symptoms': <String>[],
          },
        ],
      };

      final data = BackupData.fromJson(json);

      expect(data.cycleDayLogs.single.periodFlow, isNull);
    },
  );
}
