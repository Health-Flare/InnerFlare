// Desktop/CI test runners have no platform channel, so sqflite needs the
// FFI implementation instead (see CLAUDE.md "Troubleshooting").

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Call once from a test file's `setUpAll` before any code touches the
/// database, e.g.:
///
/// ```dart
/// setUpAll(useInMemoryTestDatabaseFactory);
/// ```
void useInMemoryTestDatabaseFactory() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}

/// Opens a fresh in-memory database for a single test.
Future<Database> openInMemoryTestDatabase({
  required Future<void> Function(Database db, int version) onCreate,
  int version = 1,
}) {
  return databaseFactory.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(version: version, onCreate: onCreate),
  );
}
