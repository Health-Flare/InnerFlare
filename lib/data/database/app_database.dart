import 'dart:io';

import 'package:inner_flare/core/security/backup_exclusion.dart';
import 'package:inner_flare/core/security/biometric_gate.dart';
import 'package:inner_flare/core/security/db_passphrase_store.dart';
import 'package:inner_flare/core/security/screen_lock_probe.dart';
import 'package:inner_flare/data/database/schema.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_sqlcipher/sqflite.dart' as sqlcipher;

export 'package:inner_flare/core/security/db_passphrase_store.dart'
    show BiometricAuthenticationFailure, DatabaseKeyUnavailable, KeyProtection;

/// Opens the app's single SQLite file, encrypted at rest with SQLCipher.
///
/// Privacy, layered:
/// - The file lives in the app's private support directory (never
///   Documents, which is user-visible via the Files app / file sharing),
///   under a name that doesn't advertise what it is.
/// - Its contents are encrypted with a passphrase that itself never
///   touches disk; it lives only in the platform secure key store (see
///   [DbPassphraseStore]).
/// - Where the phone has a screen lock (iOS, Android 11+), the OS itself
///   releases that passphrase only after face, fingerprint, or the screen
///   lock: the OS prompt is the unlock. Elsewhere, [BiometricGate] asks
///   first, as before.
/// - It's excluded from iCloud/iTunes and Android auto-backups, so the
///   only way data leaves the device is the explicit export feature.
class AppDatabase {
  /// [biometricGate]: pass one (tests, store screenshots, video mode) to
  /// make that gate the whole unlock, with no OS-bound key slot, exactly
  /// as before key binding. Omit it in the app.
  AppDatabase({
    BiometricGate? biometricGate,
    DbPassphraseStore? passphraseStore,
  }) : _passphraseStore =
           passphraseStore ??
           (biometricGate != null
               ? DbPassphraseStore(
                   legacyGate: biometricGate,
                   keyBinding: const NoKeyBinding(),
                 )
               : DbPassphraseStore());

  static const _fileName = '.if_store.db';

  final DbPassphraseStore _passphraseStore;

  /// How the key was protected when [open] last succeeded; null before.
  KeyProtection? get protection => _protection;
  KeyProtection? _protection;

  Future<Database> open() async {
    final directory = await getApplicationSupportDirectory();
    final path = p.join(directory.path, _fileName);

    // Unlocking prompts (and fails closed) before anything is opened.
    final key = await _passphraseStore.unlock(
      databaseExists: await File(path).exists(),
    );

    final db = await sqlcipher.openDatabase(
      path,
      password: key.passphrase,
      version: schemaVersion,
      onCreate: onCreate,
      onUpgrade: onUpgrade,
    );

    await excludeFromBackup(path);
    _protection = key.protection;
    return db;
  }
}
