// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_lock_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the app-level lock screen is currently covering the app,
/// having tripped the idle-background timeout (docs/features/app_lock.feature).
///
/// Starts unlocked: the very first unlock of a session happens through
/// [AppDatabase]'s own biometric gate the first time data is read, not
/// through this — this provider only covers re-locking after the app has
/// already been in use.

@ProviderFor(AppLock)
final appLockProvider = AppLockProvider._();

/// Whether the app-level lock screen is currently covering the app,
/// having tripped the idle-background timeout (docs/features/app_lock.feature).
///
/// Starts unlocked: the very first unlock of a session happens through
/// [AppDatabase]'s own biometric gate the first time data is read, not
/// through this — this provider only covers re-locking after the app has
/// already been in use.
final class AppLockProvider extends $NotifierProvider<AppLock, bool> {
  /// Whether the app-level lock screen is currently covering the app,
  /// having tripped the idle-background timeout (docs/features/app_lock.feature).
  ///
  /// Starts unlocked: the very first unlock of a session happens through
  /// [AppDatabase]'s own biometric gate the first time data is read, not
  /// through this — this provider only covers re-locking after the app has
  /// already been in use.
  AppLockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appLockProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appLockHash();

  @$internal
  @override
  AppLock create() => AppLock();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$appLockHash() => r'd08f8dae5fd1c3f69b679f9bf413e41371f63070';

/// Whether the app-level lock screen is currently covering the app,
/// having tripped the idle-background timeout (docs/features/app_lock.feature).
///
/// Starts unlocked: the very first unlock of a session happens through
/// [AppDatabase]'s own biometric gate the first time data is read, not
/// through this — this provider only covers re-locking after the app has
/// already been in use.

abstract class _$AppLock extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
