import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/core/security/backup_encryption.dart';
import 'package:inner_flare/data/export/backup_file_codec.dart';
import 'package:inner_flare/data/export/backup_importer.dart';
import 'package:inner_flare/features/export/backup_error_messages.dart';

// Issue #100: "Couldn't export: $error" / "Couldn't import: $error" put raw
// exception text (file paths, internals) in front of the user.

void main() {
  final unknown = const FileSystemException(
    'Cannot open file',
    '/private/var/mobile/Containers/Data/tmp/backup.ifbackup',
  );

  group('export', () {
    test('an unknown error shows a fixed plain message', () {
      expect(
        exportErrorMessage(unknown, showDetail: false),
        "Couldn't create the backup. Nothing was changed.",
      );
    });

    test('debug builds also show the raw detail under it', () {
      final message = exportErrorMessage(unknown, showDetail: true);
      expect(message, startsWith(exportFailedMessage));
      expect(message, contains('Cannot open file'));
    });
  });

  group('import', () {
    test('an unknown error shows a fixed plain message', () {
      expect(
        importErrorMessage(unknown, showDetail: false),
        "Couldn't import this backup. Try again, or check the file.",
      );
    });

    test('debug builds also show the raw detail under it', () {
      final message = importErrorMessage(unknown, showDetail: true);
      expect(message, startsWith(importFailedMessage));
      expect(message, contains('Cannot open file'));
    });

    test('regression guard: known cases keep their specific messages', () {
      for (final known in <Object>[
        const InvalidBackupFile(),
        const BackupPassphraseRequired(),
        const IncorrectBackupPassphrase(),
        const UnsupportedBackupSchemaVersion(99),
      ]) {
        expect(
          importErrorMessage(known, showDetail: false),
          known.toString(),
          reason: '${known.runtimeType}',
        );
      }
    });
  });
}
