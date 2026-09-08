import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Generates and retrieves the passphrase that encrypts the on-device
/// SQLite file. The passphrase itself lives only in the platform's secure
/// key store (iOS Keychain / Android Keystore-backed encrypted prefs) —
/// never in the database file, never in plain app storage.
class DbPassphraseStore {
  DbPassphraseStore({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.unlocked_this_device,
            ),
          );

  static const _key = 'inner_flare.db_passphrase';

  final FlutterSecureStorage _storage;

  /// Returns the existing passphrase, or generates and stores a new
  /// cryptographically random one on first run.
  Future<String> getOrCreate() async {
    final existing = await _storage.read(key: _key);
    if (existing != null) return existing;

    final generated = _generatePassphrase();
    await _storage.write(key: _key, value: generated);
    return generated;
  }

  String _generatePassphrase() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }
}
