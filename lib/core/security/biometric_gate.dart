import 'package:local_auth/local_auth.dart';

/// Gates access to the encrypted database behind the device's biometrics
/// (or passcode fallback). Abstracted behind an interface so tests and
/// desktop/CI runs — which have no biometric hardware — can supply a fake.
abstract class BiometricGate {
  /// Returns true if the user is allowed through: either they authenticated
  /// successfully, or the device has no biometrics/passcode configured at
  /// all, in which case we can't gate on something that doesn't exist.
  Future<bool> authenticate();
}

class LocalAuthBiometricGate implements BiometricGate {
  LocalAuthBiometricGate({LocalAuthentication? auth})
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> authenticate() async {
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      if (!supported && !canCheck) {
        // Nothing to gate with — the key is still protected at rest by
        // the OS keystore, it just won't prompt on this device.
        return true;
      }

      return await _auth.authenticate(
        localizedReason: 'Unlock InnerFlare to view your data',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
    } on Exception {
      // Couldn't even determine whether biometrics are available (e.g. the
      // platform plugin isn't wired up). Fail open rather than locking the
      // user out of their own on-device data over a capability check —
      // the data is still encrypted at rest either way.
      return true;
    }
  }
}

/// Always succeeds without prompting — for tests and any environment where
/// a real biometric prompt would hang or isn't meaningful.
class AlwaysAllowBiometricGate implements BiometricGate {
  const AlwaysAllowBiometricGate();

  @override
  Future<bool> authenticate() async => true;
}
