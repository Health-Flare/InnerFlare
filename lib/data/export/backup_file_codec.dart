import 'dart:convert';

import 'package:inner_flare/core/security/backup_encryption.dart';
import 'package:inner_flare/data/export/backup_data.dart';

/// Encodes/decodes the on-disk envelope around a [BackupData] payload:
/// the salt/nonce/mac/ciphertext structure for "encrypt export" (the
/// default), and the plain JSON structure when the user turns encryption
/// off (docs/features/export.feature).
///
/// Files written now carry a generic marker, `"fmt": "ifb1"`, and nothing
/// else that names the app (issue #100): an encrypted file is only the
/// marker, the KDF settings and the ciphertext. Files from Inner Flare 1.0
/// to 1.3 used `"inner_flare_export": true` plus `"envelope_version": 1`;
/// [decode] still reads those.
///
/// This is a thin wrapper around [BackupEncryption]: it owns the file
/// shape (what's JSON, what's base64, which fields exist), not the
/// cryptography itself.
class BackupFileCodec {
  BackupFileCodec({BackupEncryption? encryption})
    : _encryption = encryption ?? BackupEncryption();

  /// The format marker written into every new file. Changed only if the
  /// envelope shape itself changes (not on every database schema_version
  /// bump, which lives inside the payload, see [BackupData.schemaVersion]).
  static const formatMarker = 'ifb1';

  /// The envelope key holding [formatMarker].
  static const formatKey = 'fmt';

  /// The marker files from Inner Flare 1.0 to 1.3 carry instead of
  /// [formatKey]. Read only, never written.
  static const _legacyMarkerKey = 'inner_flare_export';

  final BackupEncryption _encryption;

  /// Encodes [data] as the on-disk file contents. Plaintext unless
  /// [passphrase] is provided, in which case the payload is
  /// AES-256-GCM-encrypted and the plaintext is never written to disk at
  /// any point during export. The export screen asks for a passphrase by
  /// default; plaintext is the user's explicit opt-out.
  Future<String> encode(BackupData data, {String? passphrase}) async {
    final payloadBytes = utf8.encode(jsonEncode(data.toJson()));

    if (passphrase == null) {
      return jsonEncode({
        formatKey: formatMarker,
        'encrypted': false,
        'data': data.toJson(),
      });
    }

    final encrypted = await _encryption.encrypt(payloadBytes, passphrase);
    return jsonEncode({
      formatKey: formatMarker,
      'encrypted': true,
      'kdf_iterations': encrypted.iterations,
      'salt': base64Encode(encrypted.salt),
      'nonce': base64Encode(encrypted.nonce),
      'mac': base64Encode(encrypted.mac),
      'ciphertext': base64Encode(encrypted.ciphertext),
    });
  }

  /// Whether the file at [contents] is passphrase-encrypted, without
  /// decrypting it, lets the import flow decide whether to prompt for a
  /// passphrase before attempting [decode].
  ///
  /// Throws [InvalidBackupFile] if [contents] isn't a recognizable Inner
  /// Flare backup at all.
  bool isEncrypted(String contents) {
    final envelope = _parseEnvelope(contents);
    return envelope['encrypted'] == true;
  }

  /// Decodes [contents] back into [BackupData]. [passphrase] is required
  /// (and must be correct) if the file is encrypted; ignored otherwise.
  ///
  /// Throws [InvalidBackupFile] for anything that isn't a well-formed
  /// Inner Flare backup, [BackupPassphraseRequired] if the file is
  /// encrypted and no passphrase was given, and
  /// [IncorrectBackupPassphrase] if one was given but doesn't match.
  Future<BackupData> decode(String contents, {String? passphrase}) async {
    final envelope = _parseEnvelope(contents);

    final Object? rawPayload;
    if (envelope['encrypted'] == true) {
      if (passphrase == null) {
        throw const BackupPassphraseRequired();
      }
      final decryptedBytes = await _encryption.decrypt(
        _encryptedBackupFrom(envelope),
        passphrase,
      );
      rawPayload = _tryDecodeJson(utf8.decode(decryptedBytes));
    } else {
      rawPayload = envelope['data'];
    }

    if (rawPayload is! Map<String, Object?>) {
      throw const InvalidBackupFile();
    }

    try {
      return BackupData.fromJson(rawPayload);
    } on FormatException {
      throw const InvalidBackupFile();
    }
  }

  /// Accepts the current envelope (`"fmt": "ifb1"`) and the 1.0 to 1.3
  /// one (`"inner_flare_export": true, "envelope_version": 1`). Both have
  /// the same `encrypted` / `data` / salt, nonce, mac, ciphertext fields.
  Map<String, Object?> _parseEnvelope(String contents) {
    final parsed = _tryDecodeJson(contents);
    if (parsed is! Map<String, Object?>) {
      throw const InvalidBackupFile();
    }
    final isCurrent = parsed[formatKey] == formatMarker;
    final isLegacy =
        parsed[_legacyMarkerKey] == true && parsed['envelope_version'] is int;
    if (!isCurrent && !isLegacy) {
      throw const InvalidBackupFile();
    }
    return parsed;
  }

  EncryptedBackup _encryptedBackupFrom(Map<String, Object?> envelope) {
    try {
      return EncryptedBackup(
        salt: base64Decode(envelope['salt'] as String),
        nonce: base64Decode(envelope['nonce'] as String),
        ciphertext: base64Decode(envelope['ciphertext'] as String),
        mac: base64Decode(envelope['mac'] as String),
        iterations: envelope['kdf_iterations'] as int,
      );
    } on TypeError {
      throw const InvalidBackupFile();
    }
  }

  Object? _tryDecodeJson(String contents) {
    try {
      return jsonDecode(contents);
    } on FormatException {
      throw const InvalidBackupFile();
    }
  }
}

/// Thrown when a file selected for import isn't a well-formed Inner Flare
/// backup at all (wrong format, corrupted, or produced by something else).
class InvalidBackupFile implements Exception {
  const InvalidBackupFile();

  @override
  String toString() => 'This file is not a valid Inner Flare backup.';
}

/// Thrown by [BackupFileCodec.decode] when the file is encrypted but no
/// passphrase was supplied, distinct from [IncorrectBackupPassphrase],
/// which means a passphrase was supplied and it was wrong.
class BackupPassphraseRequired implements Exception {
  const BackupPassphraseRequired();

  @override
  String toString() => 'This backup is encrypted and requires a passphrase.';
}
