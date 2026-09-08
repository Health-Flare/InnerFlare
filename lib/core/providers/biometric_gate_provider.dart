import 'package:inner_flare/core/security/biometric_gate.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'biometric_gate_provider.g.dart';

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
@riverpod
BiometricGate biometricGate(Ref ref) => LocalAuthBiometricGate();
