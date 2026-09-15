import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/core/security/backup_encryption.dart';
import 'package:inner_flare/data/export/backup_data.dart';
import 'package:inner_flare/data/export/backup_file_codec.dart';

void main() {
  late BackupFileCodec codec;
  late BackupData data;

  setUp(() {
    codec = BackupFileCodec();
    data = BackupData(
      schemaVersion: 5,
      exportedAt: DateTime.utc(2026, 9, 15),
      cycleDayLogs: const [],
      symptoms: const [],
    );
  });

  test('a plaintext-encoded file decodes back to the same data', () async {
    final contents = await codec.encode(data);

    expect(codec.isEncrypted(contents), isFalse);
    final decoded = await codec.decode(contents);
    expect(decoded.schemaVersion, data.schemaVersion);
    expect(decoded.exportedAt, data.exportedAt);
  });

  test('an encrypted file requires the correct passphrase to decode', () async {
    final contents = await codec.encode(data, passphrase: 'p@ssphrase');

    expect(codec.isEncrypted(contents), isTrue);
    final decoded = await codec.decode(contents, passphrase: 'p@ssphrase');
    expect(decoded.schemaVersion, data.schemaVersion);
  });

  test(
    'decoding an encrypted file without a passphrase throws BackupPassphraseRequired',
    () async {
      final contents = await codec.encode(data, passphrase: 'p@ssphrase');

      expect(
        () => codec.decode(contents),
        throwsA(isA<BackupPassphraseRequired>()),
      );
    },
  );

  test(
    'decoding an encrypted file with the wrong passphrase throws IncorrectBackupPassphrase',
    () async {
      final contents = await codec.encode(data, passphrase: 'p@ssphrase');

      expect(
        () => codec.decode(contents, passphrase: 'nope'),
        throwsA(isA<IncorrectBackupPassphrase>()),
      );
    },
  );

  test('a file that is not JSON throws InvalidBackupFile', () async {
    expect(
      () => codec.decode('not json at all'),
      throwsA(isA<InvalidBackupFile>()),
    );
  });

  test(
    'valid JSON that is not an Inner Flare envelope throws InvalidBackupFile',
    () async {
      expect(
        () => codec.decode('{"some_other_app_export": true}'),
        throwsA(isA<InvalidBackupFile>()),
      );
    },
  );
}
