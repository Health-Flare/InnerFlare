import 'package:inner_flare/core/providers/key_protection_provider.dart';
import 'package:inner_flare/data/database/app_database.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sqflite_common/sqlite_api.dart';

part 'database_provider.g.dart';

/// Opens the encrypted on-device database once per app session and keeps
/// it alive; see [AppDatabase] for what "encrypted" and "on-device" mean
/// in practice.
///
/// Retries are disabled (`retry: _noRetry`). Riverpod's default retry
/// policy would otherwise silently re-run this, and so re-show the
/// biometric prompt, up to 10 times with exponential backoff whenever it
/// throws, since [BiometricAuthenticationFailure] `implements Exception`
/// rather than extending `Error`, and the default policy retries anything
/// that isn't an `Error`/`ProviderException`. That would mean a cancelled
/// prompt gets unsolicited repeat prompts moments later, contradicting
/// "the user decides when to retry" (see `UnlockErrorBanner`). The same
/// holds for the key-store errors the unlock can throw now that the OS
/// prompt itself releases the key (`KeyStoreAuthenticationFailed`,
/// `ScreenLockCheckFailure`, `DatabaseKeyUnavailable`): all `Exception`s.
///
/// Records how the key was protected in [keyProtectionStateProvider] so
/// the "no screen lock" warning can show without anything else watching
/// this provider.
@Riverpod(keepAlive: true, retry: _noRetry)
Future<Database> appDatabase(Ref ref) async {
  final appDatabase = AppDatabase();
  final db = await appDatabase.open();
  if (ref.mounted) {
    ref.read(keyProtectionStateProvider.notifier).set(appDatabase.protection);
  }
  return db;
}

Duration? _noRetry(int retryCount, Object error) => null;
