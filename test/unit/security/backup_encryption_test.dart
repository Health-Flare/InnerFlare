import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/core/security/backup_encryption.dart';

void main() {
  late BackupEncryption encryption;

  setUp(() => encryption = BackupEncryption());

  test(
    'decrypting with the correct passphrase returns the original bytes',
    () async {
      final plaintext = utf8.encode('{"hello":"world"}');

      final encrypted = await encryption.encrypt(plaintext, 'correct horse');
      final decrypted = await encryption.decrypt(encrypted, 'correct horse');

      expect(decrypted, plaintext);
    },
  );

  test(
    'decrypting with the wrong passphrase throws IncorrectBackupPassphrase',
    () async {
      final plaintext = utf8.encode('secret cycle data');
      final encrypted = await encryption.encrypt(plaintext, 'correct horse');

      expect(
        () => encryption.decrypt(encrypted, 'wrong passphrase'),
        throwsA(isA<IncorrectBackupPassphrase>()),
      );
    },
  );

  test(
    'encrypting the same plaintext twice produces different ciphertext',
    () async {
      final plaintext = utf8.encode('same data');

      final first = await encryption.encrypt(plaintext, 'passphrase');
      final second = await encryption.encrypt(plaintext, 'passphrase');

      expect(first.ciphertext, isNot(second.ciphertext));
      expect(first.salt, isNot(second.salt));
    },
  );
}
