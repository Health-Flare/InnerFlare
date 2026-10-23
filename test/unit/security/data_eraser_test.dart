import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/core/files/scratch_files.dart';
import 'package:inner_flare/core/providers/data_eraser_provider.dart';
import 'package:inner_flare/core/security/data_eraser.dart';
import 'package:inner_flare/core/security/db_passphrase_store.dart';
import 'package:inner_flare/data/database/app_database.dart';
import 'package:inner_flare/data/database/schema.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// docs/features/erase_data.feature, against a real on-disk SQLite file
/// (sqflite FFI) and flutter_secure_storage's in-memory test store.
const _keyName = 'inner_flare.db_passphrase';

/// A store whose delete fails, as a platform keystore can.
class _UndeletableStore extends DbPassphraseStore {
  _UndeletableStore();

  @override
  Future<void> delete() async => throw Exception('keystore refused (test)');
}

void main() {
  setUpAll(sqfliteFfiInit);

  late Directory support;
  late Directory temp;
  late Database db;
  late String dbPath;
  late File unrelatedTemp;
  late File exportFile;

  Future<String?> storedKey() =>
      const FlutterSecureStorage().read(key: _keyName);

  List<String> dbFiles() => [
    dbPath,
    '$dbPath-wal',
    '$dbPath-shm',
    '$dbPath-journal',
  ].where((path) => File(path).existsSync()).toList();

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({_keyName: 'secret'});
    final root = await Directory.systemTemp.createTemp('if_erase_test');
    support = await Directory(p.join(root.path, 'support')).create();
    temp = await Directory(p.join(root.path, 'tmp')).create();
    addTearDown(() => root.delete(recursive: true));

    dbPath = p.join(support.path, AppDatabase.fileName);
    db = await databaseFactoryFfi.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(version: schemaVersion, onCreate: onCreate),
    );
    await db.insert(cycleDayLogsTable, {
      'date': '2026-09-01',
      'period_flow': 'medium',
    });
    // The working files SQLite can leave next to the database.
    for (final suffix in ['-wal', '-shm', '-journal']) {
      File('$dbPath$suffix').writeAsStringSync('x');
    }

    exportFile = File(
      p.join(temp.path, 'inner_flare_backup_20260901_101500.ifbackup'),
    )..writeAsStringSync('{}');
    unrelatedTemp = File(p.join(temp.path, 'someone_elses.txt'))
      ..writeAsStringSync('keep me');
  });

  tearDown(() async {
    if (db.isOpen) await db.close();
  });

  DataEraser eraser({
    DbPassphraseStore? store,
    Future<void> Function()? clearTemporaryExports,
    Future<void> Function()? clearPickedFiles,
    Future<void> Function(File file)? deleteFile,
  }) {
    return DataEraser(
      passphraseStore: store ?? DbPassphraseStore(),
      supportDirectory: () async => support,
      clearTemporaryExports:
          clearTemporaryExports ??
          () async {
            if (exportFile.existsSync()) exportFile.deleteSync();
          },
      clearPickedFiles: clearPickedFiles,
      deleteFile: deleteFile,
    );
  }

  test('erase deletes the key, the database and its working files, and '
      'leftover exports, and closes the database first', () async {
    var pickedCleared = false;
    await eraser(
      clearPickedFiles: () async => pickedCleared = true,
    ).erase(closeDatabase: db.close);

    expect(await storedKey(), isNull);
    expect(db.isOpen, isFalse);
    expect(dbFiles(), isEmpty);
    expect(exportFile.existsSync(), isFalse);
    expect(pickedCleared, isTrue);
    expect(
      File(p.join(support.path, DataEraser.pendingMarkerName)).existsSync(),
      isFalse,
    );
  });

  test('regression guard: other files in the temp and support folders are '
      'left alone', () async {
    final otherSupport = File(p.join(support.path, 'unrelated.bin'))
      ..writeAsStringSync('keep');
    await eraser().erase(closeDatabase: db.close);

    expect(unrelatedTemp.readAsStringSync(), 'keep me');
    expect(otherSupport.readAsStringSync(), 'keep');
  });

  test('if the key cannot be deleted, nothing else is touched', () async {
    var pickedCleared = false;
    var closed = false;
    final failing = _UndeletableStore();
    final filesBefore = dbFiles();
    expect(filesBefore, contains(dbPath));

    await expectLater(
      eraser(
        store: failing,
        clearPickedFiles: () async => pickedCleared = true,
      ).erase(
        closeDatabase: () async {
          closed = true;
          await db.close();
        },
      ),
      throwsA(isA<EraseKeyDeletionFailed>()),
    );

    expect(await storedKey(), 'secret');
    expect(closed, isFalse);
    // Checked before querying: SQLite tidies its own working files on
    // the next read.
    expect(dbFiles(), filesBefore);
    expect(db.isOpen, isTrue);
    expect(await db.query(cycleDayLogsTable), hasLength(1));
    expect(exportFile.existsSync(), isTrue);
    expect(pickedCleared, isFalse);
  });

  test('once the key is gone, a failing later step does not stop the '
      'rest, and the next open finishes the job', () async {
    var pickedCleared = false;
    await eraser(
      clearTemporaryExports: () async => throw Exception('busy (test)'),
      clearPickedFiles: () async => pickedCleared = true,
      deleteFile: (file) async {
        if (file.path.endsWith('-wal')) {
          throw FileSystemException('locked (test)', file.path);
        }
        if (file.existsSync()) file.deleteSync();
      },
    ).erase(closeDatabase: db.close);

    // Finished, not thrown: the data is unreadable without its key.
    expect(await storedKey(), isNull);
    expect(pickedCleared, isTrue);
    expect(dbFiles(), ['$dbPath-wal']);
    expect(
      File(p.join(support.path, DataEraser.pendingMarkerName)).existsSync(),
      isTrue,
    );

    // A key could have been made again in between (e.g. a crash after
    // the unlock that follows): the next open still removes it with the
    // old files so the app can start clean.
    await const FlutterSecureStorage().write(key: _keyName, value: 'new');
    await DataEraser.finishPendingErase(
      directory: support,
      passphraseStore: DbPassphraseStore(),
    );
    expect(dbFiles(), isEmpty);
    expect(await storedKey(), isNull);
    expect(
      File(p.join(support.path, DataEraser.pendingMarkerName)).existsSync(),
      isFalse,
    );
  });

  test('a failing close does not stop the erase', () async {
    await eraser().erase(
      closeDatabase: () async => throw Exception('close failed (test)'),
    );
    expect(await storedKey(), isNull);
    expect(exportFile.existsSync(), isFalse);
  });

  test('regression guard: with no erase pending, opening the app never '
      'deletes anything', () async {
    await db.close();
    await DataEraser.finishPendingErase(
      directory: support,
      passphraseStore: DbPassphraseStore(),
    );
    expect(dbFiles(), hasLength(4));
    expect(await storedKey(), 'secret');
  });

  test('the app erases through the shared export scratch clean-up and '
      "file_picker's own clean-up", () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final eraser = container.read(dataEraserProvider);
    expect(eraser.clearTemporaryExports, same(ScratchFiles.clearAll));
    expect(eraser.clearPickedFiles, same(FilePicker.clearTemporaryFiles));
  });
}
