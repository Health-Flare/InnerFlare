import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/core/files/scratch_files.dart';
import 'package:inner_flare/data/export/backup_file_io.dart';
import 'package:path/path.dart' as p;

// Issue #100: backups (plain JSON by default until then) were written loose
// in the temp directory as inner_flare_backup_<time>.ifbackup and never
// deleted. Anything that could read that folder later could read every
// period, note and temperature in them.

const _pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late Directory tmp;

  setUp(() {
    root = Directory.systemTemp.createTempSync('if_scratch_test_');
    tmp = Directory(p.join(root.path, 'tmp'))..createSync();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, (call) async {
          if (call.method == 'getTemporaryDirectory') return tmp.path;
          return p.join(root.path, 'other');
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, null);
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  File touch(String relative) => File(p.join(tmp.path, relative))
    ..createSync(recursive: true)
    ..writeAsStringSync('cycle data');

  String inScratch(String name) => p.join(ScratchFiles.folderName, name);

  group('ScratchFiles.directory', () {
    test('is one app-owned folder inside the temp directory', () async {
      final dir = await ScratchFiles.directory();
      expect(dir.path, p.join(tmp.path, ScratchFiles.folderName));
      expect(dir.existsSync(), isTrue);
    });

    test('has a name that does not say what app made it', () {
      expect(ScratchFiles.folderName.toLowerCase(), isNot(contains('flare')));
      expect(ScratchFiles.folderName.toLowerCase(), isNot(contains('backup')));
    });
  });

  group('ScratchFiles.sweep (at startup)', () {
    test('empties the scratch folder', () async {
      touch(inScratch('backup_20261005_120000.ifbackup'));
      touch(inScratch('something_else.tmp'));

      await ScratchFiles.sweep(appPrivateTemp: true);

      final left = Directory(p.join(tmp.path, ScratchFiles.folderName));
      expect(left.existsSync() ? left.listSync() : const [], isEmpty);
    });

    test('removes backups versions 1.0 to 1.3 left loose in temp', () async {
      final legacy = [
        touch('inner_flare_backup_20260915_093000.ifbackup'),
        touch('inner_flare_backup_20261001_235959.ifbackup'),
      ];

      await ScratchFiles.sweep(appPrivateTemp: true);

      for (final f in legacy) {
        expect(f.existsSync(), isFalse, reason: '${f.path} should be gone');
      }
    });

    test('removes legacy backups even where temp is shared (Windows, '
        'Linux): the name is unmistakably ours', () async {
      final legacy = touch('inner_flare_backup_20260915_093000.ifbackup');
      await ScratchFiles.sweep(appPrivateTemp: false);
      expect(legacy.existsSync(), isFalse);
    });

    test('clears the copy share_plus keeps on Android', () async {
      final copy = touch('share_plus/backup_20261005_120000.ifbackup');
      await ScratchFiles.sweep(appPrivateTemp: true);
      expect(copy.existsSync(), isFalse);
    });

    test('regression guard: leaves every other file in temp alone', () async {
      final others = [
        touch('notes.txt'),
        touch('some_cache/thing.bin'),
        touch('inner_flare_settings.json'),
        touch('backup_20261005_120000.ifbackup'), // not ours: loose in temp
        touch('inner_flare_backup_latest.ifbackup'), // not our pattern
      ];

      await ScratchFiles.sweep(appPrivateTemp: true);

      for (final f in others) {
        expect(f.existsSync(), isTrue, reason: '${f.path} is not ours');
      }
    });

    test('in a shared temp folder, never touches share_plus', () async {
      final notOurs = touch('share_plus/other.txt');
      await ScratchFiles.sweep(appPrivateTemp: false);
      expect(notOurs.existsSync(), isTrue);
    });

    test('does not throw when temp is missing', () async {
      tmp.deleteSync(recursive: true);
      await ScratchFiles.sweep(appPrivateTemp: true);
    });
  });

  group('ScratchFiles.clearAll (for Erase all data)', () {
    test('deletes everything in the scratch folder', () async {
      final a = touch(inScratch('backup_20261005_120000.ifbackup'));
      final b = touch(inScratch('nested/file.bin'));

      await ScratchFiles.clearAll(appPrivateTemp: true);

      expect(a.existsSync(), isFalse);
      expect(b.existsSync(), isFalse);
    });

    test('a new file can be written after clearing', () async {
      touch(inScratch('old.ifbackup'));
      await ScratchFiles.clearAll(appPrivateTemp: true);

      final path = await BackupFileIO().writeTemporaryFile('{}');
      expect(File(path).existsSync(), isTrue);
    });
  });

  group('ScratchFiles.shareThenDelete', () {
    test('deletes the file after a share on phones', () async {
      final f = touch(inScratch('backup_20261005_120000.ifbackup'));
      var shared = false;

      await ScratchFiles.shareThenDelete(
        f.path,
        () async => shared = true,
        deleteNow: true,
      );

      expect(shared, isTrue);
      expect(f.existsSync(), isFalse);
    });

    test('deletes the file even when the share fails', () async {
      final f = touch(inScratch('backup_20261005_120000.ifbackup'));

      await expectLater(
        ScratchFiles.shareThenDelete(
          f.path,
          () async => throw Exception('share failed'),
          deleteNow: true,
        ),
        throwsException,
      );

      expect(f.existsSync(), isFalse);
    });

    test('keeps the file on desktop, where the share target may still be '
        'reading it; the next launch sweeps it', () async {
      final f = touch(inScratch('backup_20261005_120000.ifbackup'));

      await ScratchFiles.shareThenDelete(f.path, () async {}, deleteNow: false);

      expect(f.existsSync(), isTrue);
      await ScratchFiles.sweep(appPrivateTemp: false);
      expect(f.existsSync(), isFalse);
    });
  });

  group('the backup writer uses the scratch folder', () {
    test('an export file is written there, under a neutral name', () async {
      final io = BackupFileIO(now: () => DateTime.utc(2026, 10, 5, 14, 30, 7));

      final path = await io.writeTemporaryFile('{}');

      expect(p.dirname(path), p.join(tmp.path, ScratchFiles.folderName));
      expect(p.basename(path), 'backup_20261005_143007.ifbackup');
    });

    test('the file name keeps the extension the import picker filters on', () {
      final name = BackupFileIO().fileName();
      expect(p.extension(name), '.${BackupFileIO.extension}');
      expect(name.toLowerCase(), isNot(contains('flare')));
    });

    test('nothing else in lib/ calls getTemporaryDirectory()', () {
      // Every short-lived file with user data must go through ScratchFiles
      // so the startup sweep and Erase all data remove it. A new
      // getTemporaryDirectory() call elsewhere would bring #100 back.
      final offenders = [
        for (final f in Directory('lib').listSync(recursive: true))
          if (f is File &&
              f.path.endsWith('.dart') &&
              p.normalize(f.path) !=
                  p.normalize('lib/core/files/scratch_files.dart') &&
              f.readAsStringSync().contains('getTemporaryDirectory('))
            f.path,
      ];
      expect(offenders, isEmpty);
    });
  });
}
