// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'biometric_gate_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The biometric gate used to re-authenticate after the app has been
/// backgrounded past [backgroundLockTimeout] (docs/features/app_lock.feature).
///
/// Deliberately separate from the gate [AppDatabase] uses internally to
/// open the encrypted database: that connection, once opened, stays open
/// for the process's lifetime — there's no passphrase to re-derive on an
/// idle-timeout relock. This provider only guards the app-level lock
/// screen overlay, and exists as a provider (rather than being constructed
/// inline) purely so tests can override it with [AlwaysAllowBiometricGate]
/// or a fake.

@ProviderFor(biometricGate)
final biometricGateProvider = BiometricGateProvider._();

/// The biometric gate used to re-authenticate after the app has been
/// backgrounded past [backgroundLockTimeout] (docs/features/app_lock.feature).
///
/// Deliberately separate from the gate [AppDatabase] uses internally to
/// open the encrypted database: that connection, once opened, stays open
/// for the process's lifetime — there's no passphrase to re-derive on an
/// idle-timeout relock. This provider only guards the app-level lock
/// screen overlay, and exists as a provider (rather than being constructed
/// inline) purely so tests can override it with [AlwaysAllowBiometricGate]
/// or a fake.

final class BiometricGateProvider
    extends $FunctionalProvider<BiometricGate, BiometricGate, BiometricGate>
    with $Provider<BiometricGate> {
  /// The biometric gate used to re-authenticate after the app has been
  /// backgrounded past [backgroundLockTimeout] (docs/features/app_lock.feature).
  ///
  /// Deliberately separate from the gate [AppDatabase] uses internally to
  /// open the encrypted database: that connection, once opened, stays open
  /// for the process's lifetime — there's no passphrase to re-derive on an
  /// idle-timeout relock. This provider only guards the app-level lock
  /// screen overlay, and exists as a provider (rather than being constructed
  /// inline) purely so tests can override it with [AlwaysAllowBiometricGate]
  /// or a fake.
  BiometricGateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'biometricGateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$biometricGateHash();

  @$internal
  @override
  $ProviderElement<BiometricGate> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BiometricGate create(Ref ref) {
    return biometricGate(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BiometricGate value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BiometricGate>(value),
    );
  }
}

String _$biometricGateHash() => r'637f31fc85c23bdbedd2d3b761b081eb90841550';
