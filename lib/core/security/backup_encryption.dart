import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Encrypts/decrypts an export file's bytes with a user-chosen passphrase
/// (docs/features/export.feature, "Optional passphrase encrypts the export
/// file at rest"). Unrelated to [DbPassphraseStore] in
/// db_passphrase_store.dart: that passphrase is generated, lives only in
/// the platform secure key store, and protects the on-device database file.
/// This one is chosen by the user, typed in at export/import time, and
/// protects a file that, unlike the database, is expected to leave the
/// device (saved to Files, AirDropped, etc).
///
/// AES-256-GCM with a key derived via PBKDF2-HMAC-SHA256. A fresh random
/// salt and nonce are generated per encryption call, so encrypting the same
/// data with the same passphrase twice produces different ciphertext.
class BackupEncryption {
  BackupEncryption({Random? random}) : _random = random ?? Random.secure();

  static const _iterations = 210000;
  static const _keyLengthBytes = 32;
  static const _saltLengthBytes = 16;

  final Random _random;

  /// Encrypts [plaintext] with a key derived from [passphrase]. The
  /// returned [EncryptedBackup] carries everything [decrypt] needs except
  /// the passphrase itself: none of it is secret on its own.
  Future<EncryptedBackup> encrypt(
    List<int> plaintext,
    String passphrase,
  ) async {
    final salt = _randomBytes(_saltLengthBytes);
    final secretKey = await _deriveKey(passphrase, salt);

    final algorithm = AesGcm.with256bits();
    final secretBox = await algorithm.encrypt(plaintext, secretKey: secretKey);

    return EncryptedBackup(
      salt: salt,
      nonce: secretBox.nonce,
      ciphertext: secretBox.cipherText,
      mac: secretBox.mac.bytes,
      iterations: _iterations,
    );
  }

  /// Decrypts [backup] with a key derived from [passphrase].
  ///
  /// Throws [IncorrectBackupPassphrase] if the passphrase is wrong (or the
  /// file was tampered with): GCM's authentication tag check fails closed
  /// rather than returning corrupted plaintext.
  Future<List<int>> decrypt(EncryptedBackup backup, String passphrase) async {
    final secretKey = await _deriveKey(
      passphrase,
      backup.salt,
      iterations: backup.iterations,
    );

    final algorithm = AesGcm.with256bits();
    final secretBox = SecretBox(
      backup.ciphertext,
      nonce: backup.nonce,
      mac: Mac(backup.mac),
    );

    try {
      return await algorithm.decrypt(secretBox, secretKey: secretKey);
    } on SecretBoxAuthenticationError {
      throw const IncorrectBackupPassphrase();
    }
  }

  Future<SecretKey> _deriveKey(
    String passphrase,
    List<int> salt, {
    int iterations = _iterations,
  }) {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: _keyLengthBytes * 8,
    );
    return pbkdf2.deriveKeyFromPassword(password: passphrase, nonce: salt);
  }

  Uint8List _randomBytes(int length) {
    return Uint8List.fromList(
      List<int>.generate(length, (_) => _random.nextInt(256)),
    );
  }
}

/// The output of [BackupEncryption.encrypt] / input to
/// [BackupEncryption.decrypt]: everything needed to reverse the operation
/// given the correct passphrase. Safe to store or transmit as-is: the salt,
/// nonce, and MAC are not secret, only the passphrase is.
class EncryptedBackup {
  const EncryptedBackup({
    required this.salt,
    required this.nonce,
    required this.ciphertext,
    required this.mac,
    required this.iterations,
  });

  final List<int> salt;
  final List<int> nonce;
  final List<int> ciphertext;
  final List<int> mac;
  final int iterations;
}

/// Thrown by [BackupEncryption.decrypt] when the supplied passphrase does
/// not match the one used to encrypt the file (or the file is corrupt).
class IncorrectBackupPassphrase implements Exception {
  const IncorrectBackupPassphrase();

  @override
  String toString() => 'Incorrect passphrase for this backup file.';
}
