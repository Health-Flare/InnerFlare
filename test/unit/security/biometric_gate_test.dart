import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/core/security/biometric_gate.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_platform_interface/types/auth_messages.dart';

/// A [LocalAuthentication] fake that returns/throws exactly what each test
/// configures, so [LocalAuthBiometricGate] can be exercised without real
/// biometric hardware.
class _FakeLocalAuthentication extends LocalAuthentication {
  _FakeLocalAuthentication({
    this.supported = true,
    this.canCheck = true,
    this.capabilityCheckError,
    this.authenticateResult,
    this.authenticateError,
  });

  final bool supported;
  final bool canCheck;
  final Object? capabilityCheckError;
  final bool? authenticateResult;
  final Object? authenticateError;

  @override
  Future<bool> isDeviceSupported() async {
    if (capabilityCheckError != null) throw capabilityCheckError!;
    return supported;
  }

  @override
  Future<bool> get canCheckBiometrics async {
    if (capabilityCheckError != null) throw capabilityCheckError!;
    return canCheck;
  }

  @override
  Future<bool> authenticate({
    required String localizedReason,
    Iterable<AuthMessages> authMessages = const <AuthMessages>[],
    bool biometricOnly = false,
    bool sensitiveTransaction = true,
    bool persistAcrossBackgrounding = false,
  }) async {
    if (authenticateError != null) throw authenticateError!;
    return authenticateResult!;
  }
}

void main() {
  group('LocalAuthBiometricGate', () {
    test('a successful prompt authenticates', () async {
      final gate = LocalAuthBiometricGate(
        auth: _FakeLocalAuthentication(authenticateResult: true),
      );

      expect(await gate.authenticate(), isTrue);
    });

    test('a declined challenge (no exception) does not authenticate', () async {
      final gate = LocalAuthBiometricGate(
        auth: _FakeLocalAuthentication(authenticateResult: false),
      );

      expect(await gate.authenticate(), isFalse);
    });

    test(
      'cancelling the prompt fails closed, not open — regression for the '
      'bypass where a cancelled Android prompt still granted access',
      () async {
        final gate = LocalAuthBiometricGate(
          auth: _FakeLocalAuthentication(
            authenticateError: const LocalAuthException(
              code: LocalAuthExceptionCode.userCanceled,
            ),
          ),
        );

        expect(await gate.authenticate(), isFalse);
      },
    );

    for (final code in [
      LocalAuthExceptionCode.systemCanceled,
      LocalAuthExceptionCode.timeout,
      LocalAuthExceptionCode.temporaryLockout,
      LocalAuthExceptionCode.biometricLockout,
      LocalAuthExceptionCode.unknownError,
    ]) {
      test('${code.name} during authentication fails closed', () async {
        final gate = LocalAuthBiometricGate(
          auth: _FakeLocalAuthentication(
            authenticateError: LocalAuthException(code: code),
          ),
        );

        expect(await gate.authenticate(), isFalse);
      });
    }

    test('no credentials configured on the device fails open — there is '
        'nothing to gate with', () async {
      final gate = LocalAuthBiometricGate(
        auth: _FakeLocalAuthentication(
          authenticateError: const LocalAuthException(
            code: LocalAuthExceptionCode.noCredentialsSet,
          ),
        ),
      );

      expect(await gate.authenticate(), isTrue);
    });

    test(
      'no biometric/passcode support at all fails open without prompting',
      () async {
        final gate = LocalAuthBiometricGate(
          auth: _FakeLocalAuthentication(supported: false, canCheck: false),
        );

        expect(await gate.authenticate(), isTrue);
      },
    );

    test('an error checking capability fails open', () async {
      final gate = LocalAuthBiometricGate(
        auth: _FakeLocalAuthentication(
          capabilityCheckError: Exception('platform plugin not wired up'),
        ),
      );

      expect(await gate.authenticate(), isTrue);
    });

    test('an unexpected exception mid-authentication fails closed', () async {
      final gate = LocalAuthBiometricGate(
        auth: _FakeLocalAuthentication(
          authenticateError: Exception('something went wrong'),
        ),
      );

      expect(await gate.authenticate(), isFalse);
    });
  });

  group('AlwaysAllowBiometricGate', () {
    test('always authenticates', () async {
      expect(await const AlwaysAllowBiometricGate().authenticate(), isTrue);
    });
  });
}
