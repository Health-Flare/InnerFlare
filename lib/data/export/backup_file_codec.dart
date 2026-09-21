import 'dart:convert';

import 'package:inner_flare/core/security/backup_encryption.dart';
import 'package:inner_flare/data/export/backup_data.dart';

/// Encodes/decodes the on-disk envelope around a [BackupData] payload:
/// the plain JSON structure for "no encryption" export, and the
/// salt/nonce/mac/ciphertext structure for "encrypt export" (docs/features/
/// export.feature, "Optional passphrase encrypts the export file at
/// rest" / "Plaintext export is the default with encryption opt-in").
///
/// This is a thin wrapper around [BackupEncryption]: it owns the file
/// shape (what's JSON, what's base64, which fields exist), not the
/// cryptography itself.
class BackupFileCodec {
  BackupFileCodec({BackupEncryption? encryption})
    : _encryption = encryption ?? BackupEncryption();

  /// Bumped only if the envelope shape itself changes (not on every
  /// database schema_version bump, which lives inside the payload, see
  /// [BackupData.schemaVersion]).
  static const _envelopeVersion = 1;

  final BackupEncryption _encryption;

  /// Encodes [data] as the on-disk file contents. Plaintext unless
  /// [passphrase] is provided, in which case the payload is
  /// AES-256-GCM-encrypted and the plaintext is never written to disk at
  /// any point during export.
  Future<String> encode(BackupData data, {String? passphrase}) async {
    final payloadBytes = utf8.encode(jsonEncode(data.toJson()));

    if (passphrase == null) {
      return jsonEncode({
        'inner_flare_export': true,
        'envelope_version': _envelopeVersion,
        'encrypted': false,
        'data': data.toJson(),
      });
    }

    final encrypted = await _encryption.encrypt(payloadBytes, passphrase);
    return jsonEncode({
      'inner_flare_export': true,
      'envelope_version': _envelopeVersion,
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

  Map<String, Object?> _parseEnvelope(String contents) {
    final parsed = _tryDecodeJson(contents);
    if (parsed is! Map<String, Object?> ||
        parsed['inner_flare_export'] != true ||
        parsed['envelope_version'] is! int) {
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
