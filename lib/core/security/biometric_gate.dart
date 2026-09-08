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
    bool supported;
    bool canCheck;
    try {
      supported = await _auth.isDeviceSupported();
      canCheck = await _auth.canCheckBiometrics;
    } on Exception {
      // Couldn't even determine whether biometrics are available (e.g. the
      // platform plugin isn't wired up). Fail open rather than locking the
      // user out of their own on-device data over a capability check —
      // the data is still encrypted at rest either way.
      return true;
    }

    if (!supported && !canCheck) {
      // Nothing to gate with — the key is still protected at rest by
      // the OS keystore, it just won't prompt on this device.
      return true;
    }

    try {
      // A cancelled/failed/locked-out prompt does NOT resolve to false on
      // every platform — on Android in particular it throws a
      // LocalAuthException instead (see the catch clauses below), so that
      // must never be handled by the same catch-all as the capability
      // checks above. Conflating the two previously meant cancelling the
      // prompt was treated as "can't tell, fail open" and granted access
      // without authenticating at all.
      return await _auth.authenticate(
        localizedReason: 'Unlock InnerFlare to view your data',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
    } on LocalAuthException catch (e) {
      if (e.code == LocalAuthExceptionCode.noCredentialsSet) {
        // The device has no biometrics enrolled and no passcode/PIN/pattern
        // set at all — the same "nothing to gate with" case as above, not
        // a declined or failed authentication attempt.
        return true;
      }
      // Cancelled, timed out, locked out, or otherwise failed: the user did
      // not prove who they are, so fail closed.
      return false;
    } on Exception {
      // An unexpected error mid-authentication. Unlike the capability
      // checks above, we already know there's something to gate with, so
      // an unexplained failure here must not grant access.
      return false;
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
