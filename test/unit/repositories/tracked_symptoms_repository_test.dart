import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/data/database/schema.dart';
import 'package:inner_flare/data/repositories/tracked_symptoms_repository.dart';
import 'package:inner_flare/models/tracked_symptom.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../helpers/test_database.dart';

void main() {
  setUpAll(useInMemoryTestDatabaseFactory);

  late Database db;
  late TrackedSymptomsRepository repository;

  setUp(() async {
    db = await openInMemoryTestDatabase(onCreate: onCreate);
    repository = TrackedSymptomsRepository(db);
  });

  tearDown(() => db.close());

  test('every built-in symptom is seeded, enabled, in a fixed order', () async {
    final all = await repository.getAll();

    expect(all.map((s) => s.id).toList(), [
      for (final (id, _) in builtInSymptoms) id,
    ]);
    expect(all.every((s) => s.enabled), isTrue);
    expect(all.every((s) => !s.isCustom), isTrue);
  });

  test('adding a custom symptom appends it, enabled, at the end', () async {
    final added = await repository.add('Back pain');

    expect(added.label, 'Back pain');
    expect(added.isCustom, isTrue);
    expect(added.enabled, isTrue);

    final all = await repository.getAll();
    expect(all.last.id, added.id);
    expect(all.last.label, 'Back pain');
  });

  test('disabling a symptom does not remove its row', () async {
    await repository.setEnabled('cramps', false);

    final all = await repository.getAll();
    final cramps = all.firstWhere((s) => s.id == 'cramps');
    expect(cramps.enabled, isFalse);
  });

  test('renaming a built-in symptom changes only its label', () async {
    await repository.rename('cramps', 'Cramping');

    final all = await repository.getAll();
    final cramps = all.firstWhere((s) => s.id == 'cramps');
    expect(cramps.label, 'Cramping');
    expect(cramps.isCustom, isFalse);
  });

  test(
    'replaceAll wipes the catalog and inserts the given symptoms exactly',
    () async {
      await repository.replaceAll(const [
        TrackedSymptom(
          id: 'custom_1',
          label: 'Only this one',
          isCustom: true,
          enabled: true,
          sortOrder: 0,
        ),
      ]);

      final all = await repository.getAll();
      expect(all.where((s) => s.id == 'custom_1'), hasLength(1));
      // Built-ins missing from the replacement set are backfilled, never
      // left to disappear entirely.
      expect(
        all.map((s) => s.id),
        containsAll(builtInSymptoms.map((s) => s.$1)),
      );
    },
  );

  test(
    'upsertIfAbsent adds a new id but never touches an existing one',
    () async {
      await repository.rename('cramps', 'My cramps label');

      await repository.upsertIfAbsent(const [
        TrackedSymptom(
          id: 'cramps',
          label: 'Should be ignored',
          isCustom: false,
          enabled: true,
          sortOrder: 0,
        ),
        TrackedSymptom(
          id: 'custom_new',
          label: 'Brand new',
          isCustom: true,
          enabled: true,
          sortOrder: 99,
        ),
      ]);

      final all = await repository.getAll();
      expect(all.firstWhere((s) => s.id == 'cramps').label, 'My cramps label');
      expect(all.any((s) => s.id == 'custom_new'), isTrue);
    },
  );
}
