// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lock_timeout_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The idle-lock timeout setting (docs/features/app_lock.feature): how
/// long the app can sit backgrounded before returning to it requires
/// re-authentication. Backs both [AppLockGate]'s check and the settings
/// screen's picker.

@ProviderFor(LockTimeoutNotifier)
final lockTimeoutProvider = LockTimeoutNotifierProvider._();

/// The idle-lock timeout setting (docs/features/app_lock.feature): how
/// long the app can sit backgrounded before returning to it requires
/// re-authentication. Backs both [AppLockGate]'s check and the settings
/// screen's picker.
final class LockTimeoutNotifierProvider
    extends $AsyncNotifierProvider<LockTimeoutNotifier, LockTimeout> {
  /// The idle-lock timeout setting (docs/features/app_lock.feature): how
  /// long the app can sit backgrounded before returning to it requires
  /// re-authentication. Backs both [AppLockGate]'s check and the settings
  /// screen's picker.
  LockTimeoutNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lockTimeoutProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lockTimeoutNotifierHash();

  @$internal
  @override
  LockTimeoutNotifier create() => LockTimeoutNotifier();
}

String _$lockTimeoutNotifierHash() =>
    r'56975aa22588fbe206514c567ba146c2ccc4e684';

/// The idle-lock timeout setting (docs/features/app_lock.feature): how
/// long the app can sit backgrounded before returning to it requires
/// re-authentication. Backs both [AppLockGate]'s check and the settings
/// screen's picker.

abstract class _$LockTimeoutNotifier extends $AsyncNotifier<LockTimeout> {
  FutureOr<LockTimeout> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<LockTimeout>, LockTimeout>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<LockTimeout>, LockTimeout>,
              AsyncValue<LockTimeout>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
