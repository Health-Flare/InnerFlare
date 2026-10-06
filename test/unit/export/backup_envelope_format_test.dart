import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/core/security/backup_encryption.dart';
import 'package:inner_flare/data/export/backup_data.dart';
import 'package:inner_flare/data/export/backup_file_codec.dart';
import 'package:inner_flare/models/period_flow.dart';

// Issue #100: the envelope said "inner_flare_export": true in the clear,
// even on an encrypted file. New files carry a generic marker; files from
// 1.0 to 1.3 must still import.
//
// The fixtures in test/fixtures/backups/ were written by the 1.3 codec
// (main at 6fc59aa) and must never be regenerated with a newer one.

void main() {
  late BackupFileCodec codec;
  late BackupData data;

  setUp(() {
    codec = BackupFileCodec();
    data = BackupData(
      schemaVersion: 9,
      exportedAt: DateTime.utc(2026, 10, 5),
      cycleDayLogs: const [],
      symptoms: const [],
    );
  });

  String fixture(String name) =>
      File('test/fixtures/backups/$name').readAsStringSync();

  group('files written now', () {
    test('an encrypted file holds only the format marker, KDF settings and '
        'ciphertext', () async {
      final contents = await codec.encode(data, passphrase: 'p@ssphrase');
      final envelope = jsonDecode(contents) as Map<String, Object?>;

      expect(envelope['fmt'], 'ifb1');
      expect(envelope.keys.toSet(), {
        'fmt',
        'encrypted',
        'kdf_iterations',
        'salt',
        'nonce',
        'mac',
        'ciphertext',
      });
      expect(contents.toLowerCase(), isNot(contains('flare')));
    });

    test('a plain file uses the same marker and no app name', () async {
      final contents = await codec.encode(data);
      final envelope = jsonDecode(contents) as Map<String, Object?>;

      expect(envelope['fmt'], 'ifb1');
      expect(envelope.containsKey('inner_flare_export'), isFalse);
      expect(contents.toLowerCase(), isNot(contains('flare')));
    });

    test('round-trip still works for both kinds', () async {
      final plain = await codec.decode(await codec.encode(data));
      expect(plain.exportedAt, data.exportedAt);

      final enc = await codec.encode(data, passphrase: 'p@ssphrase');
      final decoded = await codec.decode(enc, passphrase: 'p@ssphrase');
      expect(decoded.exportedAt, data.exportedAt);
    });

    test('a file with an unknown format marker is rejected', () async {
      expect(
        () => codec.decode('{"fmt": "ifb99", "encrypted": false, "data": {}}'),
        throwsA(isA<InvalidBackupFile>()),
      );
    });
  });

  group('files from Inner Flare 1.0 to 1.3 still import', () {
    test('a plain 1.3 backup', () async {
      final contents = fixture('v1_3_plain.ifbackup');
      expect(codec.isEncrypted(contents), isFalse);

      final decoded = await codec.decode(contents);

      expect(decoded.schemaVersion, 8);
      expect(decoded.cycleDayLogs.single.date, DateTime.utc(2026, 8, 20));
      expect(decoded.cycleDayLogs.single.periodFlow, PeriodFlow.medium);
      expect(decoded.cycleDayLogs.single.note, 'fixture note');
      expect(decoded.symptoms.single.id, 'cramps');
    });

    test('an encrypted 1.3 backup, with its passphrase', () async {
      final contents = fixture('v1_3_encrypted.ifbackup');
      expect(codec.isEncrypted(contents), isTrue);

      final decoded = await codec.decode(
        contents,
        passphrase: 'fixture-passphrase',
      );

      expect(decoded.cycleDayLogs.single.basalBodyTempCelsius, 36.4);
      expect(decoded.symptoms.single.label, 'Cramps');
    });

    test('an encrypted 1.3 backup still refuses the wrong passphrase', () {
      expect(
        () => codec.decode(
          fixture('v1_3_encrypted.ifbackup'),
          passphrase: 'wrong',
        ),
        throwsA(isA<IncorrectBackupPassphrase>()),
      );
    });
  });
}
