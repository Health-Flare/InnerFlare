import 'package:inner_flare/core/security/backup_exclusion.dart';
import 'package:inner_flare/core/security/biometric_gate.dart';
import 'package:inner_flare/core/security/db_passphrase_store.dart';
import 'package:inner_flare/data/database/schema.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_sqlcipher/sqflite.dart' as sqlcipher;

/// Opens the app's single SQLite file, encrypted at rest with SQLCipher.
///
/// Privacy, layered:
/// - The file lives in the app's private support directory (never
///   Documents, which is user-visible via the Files app / file sharing),
///   under a name that doesn't advertise what it is.
/// - Its contents are encrypted with a passphrase that itself never
///   touches disk — it lives only in the platform secure key store (see
///   [DbPassphraseStore]).
/// - Opening it is gated behind [BiometricGate] wherever the device
///   supports biometrics/a passcode.
/// - It's excluded from iCloud/iTunes and Android auto-backups, so the
///   only way data leaves the device is the explicit export feature.
class AppDatabase {
  AppDatabase({
    BiometricGate? biometricGate,
    DbPassphraseStore? passphraseStore,
  }) : _biometricGate = biometricGate ?? LocalAuthBiometricGate(),
       _passphraseStore = passphraseStore ?? DbPassphraseStore();

  static const _fileName = '.if_store.db';

  final BiometricGate _biometricGate;
  final DbPassphraseStore _passphraseStore;

  Future<Database> open() async {
    final authenticated = await _biometricGate.authenticate();
    if (!authenticated) {
      throw const BiometricAuthenticationFailure();
    }

    final passphrase = await _passphraseStore.getOrCreate();
    final directory = await getApplicationSupportDirectory();
    final path = p.join(directory.path, _fileName);

    final db = await sqlcipher.openDatabase(
      path,
      password: passphrase,
      version: schemaVersion,
      onCreate: onCreate,
      onUpgrade: onUpgrade,
    );

    await excludeFromBackup(path);
    return db;
  }
}

/// Thrown when the user cancels or fails the biometric/passcode prompt
/// gating access to the encrypted database.
class BiometricAuthenticationFailure implements Exception {
  const BiometricAuthenticationFailure();

  @override
  String toString() =>
      'Biometric authentication was cancelled or failed, so the encrypted '
      'database was not opened.';
}
