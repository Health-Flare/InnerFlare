// The user's own "Period day" choice (issue #103) through export and
// import, against a real (in-memory, FFI) SQLite database.

import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/core/cycle_math/cycle_math.dart';
import 'package:inner_flare/data/database/schema.dart';
import 'package:inner_flare/data/export/backup_data.dart';
import 'package:inner_flare/data/export/backup_exporter.dart';
import 'package:inner_flare/data/export/backup_file_codec.dart';
import 'package:inner_flare/data/export/backup_importer.dart';
import 'package:inner_flare/data/repositories/cycle_day_log_repository.dart';
import 'package:inner_flare/data/repositories/tracked_symptoms_repository.dart';
import 'package:inner_flare/models/cycle_day_log.dart';
import 'package:inner_flare/models/period_flow.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../helpers/test_database.dart';

void main() {
  setUpAll(useInMemoryTestDatabaseFactory);

  DateTime d(int day) => DateTime.utc(2026, 3, day);

  test('toJson/fromJson round-trips the choice, and no choice', () {
    final data = BackupData(
      schemaVersion: schemaVersion,
      exportedAt: DateTime.utc(2026, 10, 4),
      cycleDayLogs: [
        CycleDayLog(
          date: d(1),
          periodFlow: PeriodFlow.spotting,
          periodDayOverride: true,
        ),
        CycleDayLog(
          date: d(10),
          periodFlow: PeriodFlow.heavy,
          periodDayOverride: false,
        ),
        CycleDayLog(date: d(20), periodFlow: PeriodFlow.medium),
      ],
      symptoms: const [],
    );

    final json = data.toJson();
    final logs = (json['cycle_day_logs']! as List).cast<Map<String, Object?>>();
    expect(logs[0]['period_day_override'], isTrue);
    expect(logs[1]['period_day_override'], isFalse);

    final back = BackupData.fromJson(json).cycleDayLogs;
    expect(back.map((l) => l.periodDayOverride), [true, false, null]);
  });

  test('a backup from before the choice existed imports with no choice', () {
    final back = BackupData.fromJson({
      'schema_version': 8,
      'exported_at': '2026-09-15T00:00:00.000Z',
      'cycle_day_logs': [
        {'date': '2026-03-01', 'period_flow': 'medium', 'symptoms': <String>[]},
      ],
    });
    expect(back.cycleDayLogs.single.periodDayOverride, isNull);
  });

  group('with a database', () {
    late Database db;
    late CycleDayLogRepository logRepository;
    late BackupExporter exporter;
    late BackupImporter importer;

    setUp(() async {
      db = await openInMemoryTestDatabase(
        onCreate: onCreate,
        version: schemaVersion,
      );
      logRepository = CycleDayLogRepository(db);
      final symptomsRepository = TrackedSymptomsRepository(db);
      exporter = BackupExporter(
        cycleDayLogRepository: logRepository,
        trackedSymptomsRepository: symptomsRepository,
        now: () => DateTime.utc(2026, 10, 4),
      );
      importer = BackupImporter(
        cycleDayLogRepository: logRepository,
        trackedSymptomsRepository: symptomsRepository,
      );
    });

    tearDown(() => db.close());

    test('export then replace-import restores both choices', () async {
      await logRepository.save(
        CycleDayLog(
          date: d(1),
          periodFlow: PeriodFlow.spotting,
          periodDayOverride: true,
        ),
      );
      await logRepository.save(
        CycleDayLog(
          date: d(10),
          periodFlow: PeriodFlow.heavy,
          periodDayOverride: false,
        ),
      );

      final contents = await exporter.buildFileContents();
      await logRepository.deleteAll();
      await importer.import(contents, strategy: ImportStrategy.replace);

      expect((await logRepository.getByDate(d(1)))?.periodDayOverride, isTrue);
      expect(
        (await logRepository.getByDate(d(10)))?.periodDayOverride,
        isFalse,
      );
      expect((await logRepository.getPeriodStartDates()).map(dateOnly), [d(1)]);
    });

    test('merge keeps the choice already on this device', () async {
      await logRepository.save(
        CycleDayLog(
          date: d(1),
          periodFlow: PeriodFlow.spotting,
          periodDayOverride: false,
        ),
      );
      final contents = await BackupFileCodec().encode(
        BackupData(
          schemaVersion: schemaVersion,
          exportedAt: DateTime.utc(2026, 10, 4),
          cycleDayLogs: [
            CycleDayLog(
              date: d(1),
              periodFlow: PeriodFlow.spotting,
              periodDayOverride: true,
            ),
          ],
          symptoms: const [],
        ),
      );

      await importer.import(contents, strategy: ImportStrategy.merge);

      expect((await logRepository.getByDate(d(1)))?.periodDayOverride, isFalse);
    });

    test('merge takes the imported choice when this device has none', () async {
      await logRepository.save(
        CycleDayLog(date: d(1), periodFlow: PeriodFlow.spotting),
      );
      final contents = await BackupFileCodec().encode(
        BackupData(
          schemaVersion: schemaVersion,
          exportedAt: DateTime.utc(2026, 10, 4),
          cycleDayLogs: [
            CycleDayLog(
              date: d(1),
              periodFlow: PeriodFlow.spotting,
              periodDayOverride: true,
            ),
          ],
          symptoms: const [],
        ),
      );

      await importer.import(contents, strategy: ImportStrategy.merge);

      expect((await logRepository.getByDate(d(1)))?.periodDayOverride, isTrue);
    });
  });
}
