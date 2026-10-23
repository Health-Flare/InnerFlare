// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(appDatabase)
final appDatabaseProvider = AppDatabaseProvider._();

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

final class AppDatabaseProvider
    extends
        $FunctionalProvider<AsyncValue<Database>, Database, FutureOr<Database>>
    with $FutureModifier<Database>, $FutureProvider<Database> {
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
  AppDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: _noRetry,
        name: r'appDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appDatabaseHash();

  @$internal
  @override
  $FutureProviderElement<Database> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Database> create(Ref ref) {
    return appDatabase(ref);
  }
}

String _$appDatabaseHash() => r'c729b0f33d0b65204213dae249ccba0ad9d412bc';
