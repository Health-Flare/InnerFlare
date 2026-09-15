import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/data/database/schema.dart';
import 'package:inner_flare/data/export/backup_data.dart';
import 'package:inner_flare/data/export/backup_exporter.dart';
import 'package:inner_flare/data/export/backup_file_codec.dart';
import 'package:inner_flare/data/export/backup_importer.dart';
import 'package:inner_flare/data/repositories/cycle_day_log_repository.dart';
import 'package:inner_flare/data/repositories/tracked_symptoms_repository.dart';
import 'package:inner_flare/models/cycle_day_log.dart';
import 'package:inner_flare/models/period_flow.dart';
import 'package:inner_flare/models/tracked_symptom.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../helpers/test_database.dart';

void main() {
  setUpAll(useInMemoryTestDatabaseFactory);

  late Database db;
  late CycleDayLogRepository logRepository;
  late TrackedSymptomsRepository symptomsRepository;
  late BackupExporter exporter;
  late BackupImporter importer;

  setUp(() async {
    db = await openInMemoryTestDatabase(
      onCreate: onCreate,
      version: schemaVersion,
    );
    logRepository = CycleDayLogRepository(db);
    symptomsRepository = TrackedSymptomsRepository(db);
    exporter = BackupExporter(
      cycleDayLogRepository: logRepository,
      trackedSymptomsRepository: symptomsRepository,
      now: () => DateTime.utc(2026, 9, 15),
    );
    importer = BackupImporter(
      cycleDayLogRepository: logRepository,
      trackedSymptomsRepository: symptomsRepository,
    );
  });

  tearDown(() => db.close());

  group('export', () {
    test('gathers every logged day and the symptom catalog', () async {
      await logRepository.save(
        CycleDayLog(
          date: DateTime.utc(2026, 9, 1),
          periodFlow: PeriodFlow.medium,
        ),
      );
      await symptomsRepository.add('Back pain');

      final contents = await exporter.buildFileContents();
      final data = await BackupFileCodec().decode(contents);

      expect(data.schemaVersion, schemaVersion);
      expect(data.exportedAt, DateTime.utc(2026, 9, 15));
      expect(data.cycleDayLogs, hasLength(1));
      expect(data.symptoms.map((s) => s.label), contains('Back pain'));
    });

    test('an encrypted export requires its passphrase to read back', () async {
      await logRepository.save(CycleDayLog(date: DateTime.utc(2026, 9, 1)));

      final contents = await exporter.buildFileContents(passphrase: 'secret');

      expect(BackupFileCodec().isEncrypted(contents), isTrue);
      final data = await BackupFileCodec().decode(
        contents,
        passphrase: 'secret',
      );
      expect(data.cycleDayLogs, hasLength(1));
    });
  });

  group('import — replace', () {
    test(
      'wipes existing logs and symptoms, replacing them with the backup',
      () async {
        await logRepository.save(
          CycleDayLog(
            date: DateTime.utc(2026, 1, 1),
            periodFlow: PeriodFlow.light,
          ),
        );
        await symptomsRepository.add('Old local symptom');

        final backup = BackupData(
          schemaVersion: schemaVersion,
          exportedAt: DateTime.utc(2026, 9, 15),
          cycleDayLogs: [
            CycleDayLog(
              date: DateTime.utc(2026, 9, 1),
              periodFlow: PeriodFlow.heavy,
            ),
          ],
          symptoms: const [],
        );
        final contents = await BackupFileCodec().encode(backup);

        await importer.import(contents, strategy: ImportStrategy.replace);

        final logs = await logRepository.getAll();
        expect(logs, hasLength(1));
        expect(_ymd(logs.single.date), (2026, 9, 1));
        expect(logs.single.periodFlow, PeriodFlow.heavy);

        final symptoms = await symptomsRepository.getAll();
        expect(symptoms.any((s) => s.label == 'Old local symptom'), isFalse);
      },
    );

    test(
      'replace still backfills built-in symptoms missing from an older export',
      () async {
        final backup = BackupData(
          schemaVersion: schemaVersion,
          exportedAt: DateTime.utc(2026, 9, 15),
          cycleDayLogs: const [],
          symptoms: const [],
        );
        final contents = await BackupFileCodec().encode(backup);

        await importer.import(contents, strategy: ImportStrategy.replace);

        final symptoms = await symptomsRepository.getAll();
        expect(
          symptoms.map((s) => s.id),
          containsAll(builtInSymptoms.map((s) => s.$1)),
        );
      },
    );
  });

  group('import — merge', () {
    test(
      'keeps existing data for a date and fills in an imported-only date',
      () async {
        await logRepository.save(
          CycleDayLog(
            date: DateTime.utc(2026, 9, 1),
            periodFlow: PeriodFlow.light,
            note: 'local note',
          ),
        );

        final backup = BackupData(
          schemaVersion: schemaVersion,
          exportedAt: DateTime.utc(2026, 9, 15),
          cycleDayLogs: [
            // Conflicting flow for the same date as the local entry above —
            // local should win.
            CycleDayLog(
              date: DateTime.utc(2026, 9, 1),
              periodFlow: PeriodFlow.heavy,
              note: 'imported note',
            ),
            // A date only the backup has — should be added.
            CycleDayLog(
              date: DateTime.utc(2026, 9, 2),
              periodFlow: PeriodFlow.medium,
            ),
          ],
          symptoms: const [],
        );
        final contents = await BackupFileCodec().encode(backup);

        await importer.import(contents, strategy: ImportStrategy.merge);

        // Keyed by calendar-date fields, not DateTime equality: dates read
        // back from the repository are local-time instances (a pre-existing
        // quirk of CycleDayLogRepository's own DateTime.parse, unrelated to
        // this import path), so comparing them directly against
        // DateTime.utc(...) would be comparing different instants even
        // though both represent the same calendar day.
        final logs = {
          for (final log in await logRepository.getAll()) _ymd(log.date): log,
        };
        expect(logs[(2026, 9, 1)]!.periodFlow, PeriodFlow.light);
        expect(logs[(2026, 9, 1)]!.note, 'local note\n\nimported note');
        expect(logs[(2026, 9, 2)]!.periodFlow, PeriodFlow.medium);
      },
    );

    test(
      'unions symptom tags for the same date rather than dropping either side',
      () async {
        await logRepository.save(
          CycleDayLog(date: DateTime.utc(2026, 9, 1), symptoms: {'cramps'}),
        );

        final backup = BackupData(
          schemaVersion: schemaVersion,
          exportedAt: DateTime.utc(2026, 9, 15),
          cycleDayLogs: [
            CycleDayLog(date: DateTime.utc(2026, 9, 1), symptoms: {'headache'}),
          ],
          symptoms: const [],
        );
        final contents = await BackupFileCodec().encode(backup);

        await importer.import(contents, strategy: ImportStrategy.merge);

        final log = await logRepository.getByDate(DateTime.utc(2026, 9, 1));
        expect(log!.symptoms, {'cramps', 'headache'});
      },
    );

    test(
      'adds an imported custom symptom not already present, without touching existing ones',
      () async {
        await symptomsRepository.rename('cramps', 'Local cramps label');

        final backup = BackupData(
          schemaVersion: schemaVersion,
          exportedAt: DateTime.utc(2026, 9, 15),
          cycleDayLogs: const [],
          symptoms: const [
            TrackedSymptom(
              id: 'cramps',
              label: 'Imported cramps label',
              isCustom: false,
              enabled: true,
              sortOrder: 0,
            ),
            TrackedSymptom(
              id: 'custom_imported',
              label: 'Imported custom symptom',
              isCustom: true,
              enabled: true,
              sortOrder: 99,
            ),
          ],
        );
        final contents = await BackupFileCodec().encode(backup);

        await importer.import(contents, strategy: ImportStrategy.merge);

        final symptoms = await symptomsRepository.getAll();
        expect(
          symptoms.firstWhere((s) => s.id == 'cramps').label,
          'Local cramps label',
        );
        expect(symptoms.any((s) => s.id == 'custom_imported'), isTrue);
      },
    );
  });

  group('import — validation', () {
    test(
      'rejects a file that is not a valid backup and writes nothing',
      () async {
        await logRepository.save(CycleDayLog(date: DateTime.utc(2026, 1, 1)));

        await expectLater(
          importer.import('not a backup', strategy: ImportStrategy.replace),
          throwsA(isA<InvalidBackupFile>()),
        );

        final logs = await logRepository.getAll();
        expect(logs, hasLength(1));
      },
    );

    test(
      'rejects a backup from a newer schema version than this app understands',
      () async {
        final backup = BackupData(
          schemaVersion: schemaVersion + 1,
          exportedAt: DateTime.utc(2026, 9, 15),
          cycleDayLogs: const [],
          symptoms: const [],
        );
        final contents = await BackupFileCodec().encode(backup);

        await expectLater(
          importer.import(contents, strategy: ImportStrategy.replace),
          throwsA(isA<UnsupportedBackupSchemaVersion>()),
        );
      },
    );

    test(
      'an older schema-version backup with no symptoms key imports without error',
      () async {
        final contents = await BackupFileCodec().encode(
          BackupData(
            schemaVersion: 4,
            exportedAt: DateTime.utc(2025, 1, 1),
            cycleDayLogs: [CycleDayLog(date: DateTime.utc(2025, 1, 1))],
            symptoms: const [],
          ),
        );

        await importer.import(contents, strategy: ImportStrategy.merge);

        final logs = await logRepository.getAll();
        expect(logs, hasLength(1));
      },
    );
  });
}

(int, int, int) _ymd(DateTime date) => (date.year, date.month, date.day);
