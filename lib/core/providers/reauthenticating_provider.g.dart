// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reauthenticating_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Tracks whether the app-lock screen currently has a biometric/passcode
/// prompt in flight (docs/features/app_lock.feature).
///
/// Presenting that native prompt briefly takes the app through
/// inactive/paused and back to resumed on its own — Face ID's system
/// sheet, or (more so) the separate device-credential activity Android
/// launches for a manual passcode — even though the user never actually
/// left the app. [AppLockGate]'s lifecycle observer can't otherwise tell
/// that apart from a real backgrounding, and would record it as time
/// spent away; with a short enough (or "Immediately") idle-lock timeout,
/// re-checking on the trailing "resumed" re-locks the app moments after
/// (or even before) that very authentication attempt unlocks it — every
/// tap of Unlock re-locking itself, permanently, with force-closing the
/// app the only way out. [AppLockGate] checks this flag and ignores
/// lifecycle transitions entirely while an unlock attempt is in flight.

@ProviderFor(reauthenticationFlag)
final reauthenticationFlagProvider = ReauthenticationFlagProvider._();

/// Tracks whether the app-lock screen currently has a biometric/passcode
/// prompt in flight (docs/features/app_lock.feature).
///
/// Presenting that native prompt briefly takes the app through
/// inactive/paused and back to resumed on its own — Face ID's system
/// sheet, or (more so) the separate device-credential activity Android
/// launches for a manual passcode — even though the user never actually
/// left the app. [AppLockGate]'s lifecycle observer can't otherwise tell
/// that apart from a real backgrounding, and would record it as time
/// spent away; with a short enough (or "Immediately") idle-lock timeout,
/// re-checking on the trailing "resumed" re-locks the app moments after
/// (or even before) that very authentication attempt unlocks it — every
/// tap of Unlock re-locking itself, permanently, with force-closing the
/// app the only way out. [AppLockGate] checks this flag and ignores
/// lifecycle transitions entirely while an unlock attempt is in flight.
final class ReauthenticationFlagProvider
    extends
        $FunctionalProvider<
          ReauthenticationFlag,
          ReauthenticationFlag,
          ReauthenticationFlag
        >
    with $Provider<ReauthenticationFlag> {
  /// Tracks whether the app-lock screen currently has a biometric/passcode
  /// prompt in flight (docs/features/app_lock.feature).
  ReauthenticationFlagProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reauthenticationFlagProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reauthenticationFlagHash();

  @$internal
  @override
  $ProviderElement<ReauthenticationFlag> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReauthenticationFlag create(Ref ref) {
    return reauthenticationFlag(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReauthenticationFlag value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReauthenticationFlag>(value),
    );
  }
}

String _$reauthenticationFlagHash() =>
    r'8f6a2e4d1c3b5a7908e6d4c2b0a8f6e4d2c0b8a6';
