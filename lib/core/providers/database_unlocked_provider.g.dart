// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database_unlocked_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the encrypted database has been opened at least once this
/// session, set by `AppUnlockGate` once `appDatabaseProvider` resolves.
///
/// Exists so other code that needs to know "has the user unlocked yet"
/// (namely `AppLockGate`, which wants to eagerly warm
/// docs/features/app_lock.feature's timeout setting) can check without
/// itself watching `appDatabaseProvider` or anything backed by it:
/// watching either would open the database, bypassing
/// docs/features/unlock.feature's "nothing is touched until the user taps
/// Unlock" rule through a side door. This was a real bug: `AppLockGate`
/// watches `lockTimeoutProvider` unconditionally on every build (see its
/// own docs), and `lockTimeoutProvider` reads its setting from the
/// database, so that single unconditional watch, needed from the very
/// first frame (`AppLockGate` wraps the whole app via
/// `MaterialApp.builder`), was silently triggering the biometric prompt
/// before the user ever saw, let alone tapped, the unlock screen.

@ProviderFor(DatabaseUnlocked)
final databaseUnlockedProvider = DatabaseUnlockedProvider._();

/// Whether the encrypted database has been opened at least once this
/// session, set by `AppUnlockGate` once `appDatabaseProvider` resolves.
///
/// Exists so other code that needs to know "has the user unlocked yet"
/// (namely `AppLockGate`, which wants to eagerly warm
/// docs/features/app_lock.feature's timeout setting) can check without
/// itself watching `appDatabaseProvider` or anything backed by it:
/// watching either would open the database, bypassing
/// docs/features/unlock.feature's "nothing is touched until the user taps
/// Unlock" rule through a side door. This was a real bug: `AppLockGate`
/// watches `lockTimeoutProvider` unconditionally on every build (see its
/// own docs), and `lockTimeoutProvider` reads its setting from the
/// database, so that single unconditional watch, needed from the very
/// first frame (`AppLockGate` wraps the whole app via
/// `MaterialApp.builder`), was silently triggering the biometric prompt
/// before the user ever saw, let alone tapped, the unlock screen.
final class DatabaseUnlockedProvider
    extends $NotifierProvider<DatabaseUnlocked, bool> {
  /// Whether the encrypted database has been opened at least once this
  /// session, set by `AppUnlockGate` once `appDatabaseProvider` resolves.
  ///
  /// Exists so other code that needs to know "has the user unlocked yet"
  /// (namely `AppLockGate`, which wants to eagerly warm
  /// docs/features/app_lock.feature's timeout setting) can check without
  /// itself watching `appDatabaseProvider` or anything backed by it:
  /// watching either would open the database, bypassing
  /// docs/features/unlock.feature's "nothing is touched until the user taps
  /// Unlock" rule through a side door. This was a real bug: `AppLockGate`
  /// watches `lockTimeoutProvider` unconditionally on every build (see its
  /// own docs), and `lockTimeoutProvider` reads its setting from the
  /// database, so that single unconditional watch, needed from the very
  /// first frame (`AppLockGate` wraps the whole app via
  /// `MaterialApp.builder`), was silently triggering the biometric prompt
  /// before the user ever saw, let alone tapped, the unlock screen.
  DatabaseUnlockedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'databaseUnlockedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$databaseUnlockedHash();

  @$internal
  @override
  DatabaseUnlocked create() => DatabaseUnlocked();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$databaseUnlockedHash() => r'cd2f4bfacbad87f099bf30df41de413ecda47e48';

/// Whether the encrypted database has been opened at least once this
/// session, set by `AppUnlockGate` once `appDatabaseProvider` resolves.
///
/// Exists so other code that needs to know "has the user unlocked yet"
/// (namely `AppLockGate`, which wants to eagerly warm
/// docs/features/app_lock.feature's timeout setting) can check without
/// itself watching `appDatabaseProvider` or anything backed by it:
/// watching either would open the database, bypassing
/// docs/features/unlock.feature's "nothing is touched until the user taps
/// Unlock" rule through a side door. This was a real bug: `AppLockGate`
/// watches `lockTimeoutProvider` unconditionally on every build (see its
/// own docs), and `lockTimeoutProvider` reads its setting from the
/// database, so that single unconditional watch, needed from the very
/// first frame (`AppLockGate` wraps the whole app via
/// `MaterialApp.builder`), was silently triggering the biometric prompt
/// before the user ever saw, let alone tapped, the unlock screen.

abstract class _$DatabaseUnlocked extends $Notifier<bool> {
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
