// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Opens the encrypted on-device database once per app session and keeps
/// it alive — see [AppDatabase] for what "encrypted" and "on-device" mean
/// in practice.
///
/// Retries are disabled (`retry: _noRetry`). Riverpod's default retry
/// policy would otherwise silently re-run this — and so re-show the
/// biometric prompt — up to 10 times with exponential backoff whenever it
/// throws, since [BiometricAuthenticationFailure] `implements Exception`
/// rather than extending `Error`, and the default policy retries anything
/// that isn't an `Error`/`ProviderException`. That would mean a cancelled
/// prompt gets unsolicited repeat prompts moments later, contradicting
/// "the user decides when to retry" (see `UnlockErrorBanner`).

@ProviderFor(appDatabase)
final appDatabaseProvider = AppDatabaseProvider._();

/// Opens the encrypted on-device database once per app session and keeps
/// it alive — see [AppDatabase] for what "encrypted" and "on-device" mean
/// in practice.
///
/// Retries are disabled (`retry: _noRetry`). Riverpod's default retry
/// policy would otherwise silently re-run this — and so re-show the
/// biometric prompt — up to 10 times with exponential backoff whenever it
/// throws, since [BiometricAuthenticationFailure] `implements Exception`
/// rather than extending `Error`, and the default policy retries anything
/// that isn't an `Error`/`ProviderException`. That would mean a cancelled
/// prompt gets unsolicited repeat prompts moments later, contradicting
/// "the user decides when to retry" (see `UnlockErrorBanner`).

final class AppDatabaseProvider
    extends
        $FunctionalProvider<AsyncValue<Database>, Database, FutureOr<Database>>
    with $FutureModifier<Database>, $FutureProvider<Database> {
  /// Opens the encrypted on-device database once per app session and keeps
  /// it alive — see [AppDatabase] for what "encrypted" and "on-device" mean
  /// in practice.
  ///
  /// Retries are disabled (`retry: _noRetry`). Riverpod's default retry
  /// policy would otherwise silently re-run this — and so re-show the
  /// biometric prompt — up to 10 times with exponential backoff whenever it
  /// throws, since [BiometricAuthenticationFailure] `implements Exception`
  /// rather than extending `Error`, and the default policy retries anything
  /// that isn't an `Error`/`ProviderException`. That would mean a cancelled
  /// prompt gets unsolicited repeat prompts moments later, contradicting
  /// "the user decides when to retry" (see `UnlockErrorBanner`).
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

String _$appDatabaseHash() => r'a17f9c94294b1a0cb4242c89bba009e650d216cf';
