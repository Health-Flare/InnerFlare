import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/core/providers/disclaimer_acknowledged_provider.dart';
import 'package:inner_flare/core/providers/security_settings_repository_provider.dart';
import 'package:inner_flare/data/database/schema.dart';
import 'package:inner_flare/data/repositories/security_settings_repository.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../helpers/test_database.dart';

void main() {
  setUpAll(useInMemoryTestDatabaseFactory);

  late Database db;

  setUp(() async {
    db = await openInMemoryTestDatabase(
      onCreate: onCreate,
      version: schemaVersion,
    );
  });

  tearDown(() => db.close());

  test('starts false and a new container still reads true after '
      'acknowledge', () async {
    final first = _container(db);
    addTearDown(first.dispose);

    expect(await first.read(disclaimerAcknowledgedProvider.future), isFalse);

    await first.read(disclaimerAcknowledgedProvider.notifier).acknowledge();
    expect(first.read(disclaimerAcknowledgedProvider).requireValue, isTrue);

    final second = _container(db);
    addTearDown(second.dispose);
    expect(await second.read(disclaimerAcknowledgedProvider.future), isTrue);
  });
}

ProviderContainer _container(Database db) {
  return ProviderContainer(
    overrides: [
      securitySettingsRepositoryProvider.overrideWith(
        (ref) async => SecuritySettingsRepository(db),
      ),
    ],
  );
}
