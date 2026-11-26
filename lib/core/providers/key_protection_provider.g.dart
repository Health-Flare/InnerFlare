// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'key_protection_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// How the database key was protected the last time it was unlocked this
/// session; null until then (and in tests, screenshots and video mode,
/// which override `appDatabaseProvider`).
///
/// Set by `appDatabaseProvider` itself, so nothing that reads this ever
/// opens the database (see database_unlocked_provider.dart for why that
/// matters).

@ProviderFor(KeyProtectionState)
final keyProtectionStateProvider = KeyProtectionStateProvider._();

/// How the database key was protected the last time it was unlocked this
/// session; null until then (and in tests, screenshots and video mode,
/// which override `appDatabaseProvider`).
///
/// Set by `appDatabaseProvider` itself, so nothing that reads this ever
/// opens the database (see database_unlocked_provider.dart for why that
/// matters).
final class KeyProtectionStateProvider
    extends $NotifierProvider<KeyProtectionState, KeyProtection?> {
  /// How the database key was protected the last time it was unlocked this
  /// session; null until then (and in tests, screenshots and video mode,
  /// which override `appDatabaseProvider`).
  ///
  /// Set by `appDatabaseProvider` itself, so nothing that reads this ever
  /// opens the database (see database_unlocked_provider.dart for why that
  /// matters).
  KeyProtectionStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'keyProtectionStateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$keyProtectionStateHash();

  @$internal
  @override
  KeyProtectionState create() => KeyProtectionState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(KeyProtection? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<KeyProtection?>(value),
    );
  }
}

String _$keyProtectionStateHash() =>
    r'4edc4316170267e266bd6f58c136bbd23a9da284';

/// How the database key was protected the last time it was unlocked this
/// session; null until then (and in tests, screenshots and video mode,
/// which override `appDatabaseProvider`).
///
/// Set by `appDatabaseProvider` itself, so nothing that reads this ever
/// opens the database (see database_unlocked_provider.dart for why that
/// matters).

abstract class _$KeyProtectionState extends $Notifier<KeyProtection?> {
  KeyProtection? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<KeyProtection?, KeyProtection?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<KeyProtection?, KeyProtection?>,
              KeyProtection?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Whether to warn that anyone holding the phone can open the app: the
/// phone has no screen lock, or the last unlock this session found none.
/// False when it can't tell, so a probe hiccup never shows a scary
/// warning; the unlock itself fails closed on its own in that case.

@ProviderFor(showNoScreenLockWarning)
final showNoScreenLockWarningProvider = ShowNoScreenLockWarningProvider._();

/// Whether to warn that anyone holding the phone can open the app: the
/// phone has no screen lock, or the last unlock this session found none.
/// False when it can't tell, so a probe hiccup never shows a scary
/// warning; the unlock itself fails closed on its own in that case.

final class ShowNoScreenLockWarningProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether to warn that anyone holding the phone can open the app: the
  /// phone has no screen lock, or the last unlock this session found none.
  /// False when it can't tell, so a probe hiccup never shows a scary
  /// warning; the unlock itself fails closed on its own in that case.
  ShowNoScreenLockWarningProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'showNoScreenLockWarningProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$showNoScreenLockWarningHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return showNoScreenLockWarning(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$showNoScreenLockWarningHash() =>
    r'823a212dbb48e5bf833dd64047f3d6b69cb05a5b';

/// The probe behind [phoneHasScreenLockProvider]; a provider so tests can
/// swap in a fake.

@ProviderFor(screenLockProbe)
final screenLockProbeProvider = ScreenLockProbeProvider._();

/// The probe behind [phoneHasScreenLockProvider]; a provider so tests can
/// swap in a fake.

final class ScreenLockProbeProvider
    extends
        $FunctionalProvider<ScreenLockProbe, ScreenLockProbe, ScreenLockProbe>
    with $Provider<ScreenLockProbe> {
  /// The probe behind [phoneHasScreenLockProvider]; a provider so tests can
  /// swap in a fake.
  ScreenLockProbeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'screenLockProbeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$screenLockProbeHash();

  @$internal
  @override
  $ProviderElement<ScreenLockProbe> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ScreenLockProbe create(Ref ref) {
    return screenLockProbe(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ScreenLockProbe value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ScreenLockProbe>(value),
    );
  }
}

String _$screenLockProbeHash() => r'ae55e475a98d6f8422518b241b129f2b2b184242';

/// Whether the phone has a screen lock: true, false, or null when it
/// can't tell (including platforms with no `local_auth` at all, such as
/// the test runner). Never prompts, and never opens the database.
///
/// Only drives the "no screen lock" warning, so "can't tell" shows
/// nothing. The unlock itself never relies on this: it asks the probe
/// again and fails closed when it can't tell (see `DbPassphraseStore`).

@ProviderFor(phoneHasScreenLock)
final phoneHasScreenLockProvider = PhoneHasScreenLockProvider._();

/// Whether the phone has a screen lock: true, false, or null when it
/// can't tell (including platforms with no `local_auth` at all, such as
/// the test runner). Never prompts, and never opens the database.
///
/// Only drives the "no screen lock" warning, so "can't tell" shows
/// nothing. The unlock itself never relies on this: it asks the probe
/// again and fails closed when it can't tell (see `DbPassphraseStore`).

final class PhoneHasScreenLockProvider
    extends $FunctionalProvider<AsyncValue<bool?>, bool?, FutureOr<bool?>>
    with $FutureModifier<bool?>, $FutureProvider<bool?> {
  /// Whether the phone has a screen lock: true, false, or null when it
  /// can't tell (including platforms with no `local_auth` at all, such as
  /// the test runner). Never prompts, and never opens the database.
  ///
  /// Only drives the "no screen lock" warning, so "can't tell" shows
  /// nothing. The unlock itself never relies on this: it asks the probe
  /// again and fails closed when it can't tell (see `DbPassphraseStore`).
  PhoneHasScreenLockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'phoneHasScreenLockProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$phoneHasScreenLockHash();

  @$internal
  @override
  $FutureProviderElement<bool?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool?> create(Ref ref) {
    return phoneHasScreenLock(ref);
  }
}

String _$phoneHasScreenLockHash() =>
    r'e2a56a43763532b74dc96315154fa3ca62cde213';
