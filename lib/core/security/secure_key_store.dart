import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// One slot in the platform secure key store (iOS Keychain / Android
/// Keystore-backed prefs), holding string values by key.
///
/// An interface so [DbPassphraseStore]'s migration from the old, unbound
/// slot to the new, user-presence-bound slot can be unit tested against a
/// fake that fails at exactly the step a test chooses.
abstract class SecureKeyStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// Thrown by a [SecureKeyStore] when the OS asked the user to prove who
/// they are (face, fingerprint, or screen lock) and that didn't succeed:
/// cancelled, failed, timed out, or locked out.
///
/// Kept apart from every other storage error on purpose: a cancelled
/// prompt must fail closed and leave the retry to the user, while an
/// unexplained storage error during key migration falls back to the old
/// key (see [DbPassphraseStore]).
class KeyStoreAuthenticationFailed implements Exception {
  const KeyStoreAuthenticationFailed(this.detail);

  final String detail;

  @override
  String toString() => 'The phone did not confirm it was you ($detail).';
}

/// iOS Security framework status codes that mean "the user didn't
/// authenticate", as opposed to a storage fault.
const _iosAuthFailureStatuses = {
  -128, // errSecUserCanceled
  -25293, // errSecAuthFailed
  -25308, // errSecInteractionNotAllowed (device locked, app not active)
};

/// Whether [error], thrown by flutter_secure_storage, means the OS prompt
/// for the user's face, fingerprint, or screen lock didn't succeed.
///
/// Matches what the plugin actually sends (flutter_secure_storage 11.2.0):
/// - iOS: `FlutterError(code: "Unexpected security result code",
///   details: OSStatus)`.
/// - Android: `result.error("Exception encountered", message, stackTrace)`.
///   A prompt that didn't succeed (cancelled, negative button, timeout,
///   lockout) is an exception whose message starts "Biometric
///   authentication error [code]:", either as the message itself or, on
///   the slot's very first use (when the plugin sets the namespace up), as
///   a "Caused by:" further down the stack trace in `details`.
bool isAuthenticationFailure(Object error) {
  if (error is! PlatformException) return false;
  final details = error.details;
  if (details is int && _iosAuthFailureStatuses.contains(details)) {
    return true;
  }
  const androidMarker = 'Biometric authentication error [';
  final message = error.message ?? '';
  if (message.startsWith(androidMarker)) return true;
  return details is String && details.contains(androidMarker);
}

/// [SecureKeyStore] over flutter_secure_storage, translating a failed or
/// cancelled OS prompt into [KeyStoreAuthenticationFailed].
class FlutterSecureKeyStore implements SecureKeyStore {
  const FlutterSecureKeyStore(this._storage);

  /// The slot every install before key binding used: no user-presence
  /// requirement, so reading it needs no prompt.
  ///
  /// `resetOnError: false` (the plugin defaults to true on Android): on a
  /// storage error the plugin would otherwise delete every value it holds,
  /// this key included, and with it the only way to open the user's data.
  /// An error that reaches the app can be retried; a deleted key can't.
  /// Changing it doesn't move the data: Android keys the store by its
  /// preferences name and prefix, not by these options.
  factory FlutterSecureKeyStore.unbound() => const FlutterSecureKeyStore(
    FlutterSecureStorage(
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.unlocked_this_device,
      ),
      aOptions: AndroidOptions(resetOnError: false),
    ),
  );

  /// The slot the OS only releases after the user proves who they are:
  /// face, fingerprint, or the phone's screen lock.
  ///
  /// iOS: `.userPresence` (biometrics or device passcode), deliberately
  /// not `.biometryCurrentSet`, which destroys the item when a face or
  /// finger is added or removed, and the user's whole history with it.
  /// `unlocked_this_device` keeps it off backups and other devices.
  ///
  /// Android: a Keystore key that needs a strong biometric or the device
  /// credential for every use (`biometricOrDeviceCredential`). On Android
  /// 11+ the plugin passes both to `setUserAuthenticationParameters`, and
  /// the Keystore then binds the key to the screen lock's root SID, which
  /// does not change when fingerprints are enrolled or removed. Android 9
  /// and 10 would instead bind it to the enrolled biometrics only (and the
  /// key would be destroyed on enrolment change), so [KeyBindingSupport]
  /// never uses this slot there.
  /// - `enforceBiometrics`: refuse to create the key on a phone with no
  ///   screen lock, rather than silently creating one with no auth.
  /// - `resetOnError: false`: never let the plugin wipe the slot on its
  ///   own; errors come back to the app instead.
  /// - `migrateOnAlgorithmChange` stays on (the default): the plugin
  ///   treats a brand new namespace as "moving from the default algorithm
  ///   to this one", and with it off that first use fails for good.
  /// - Its own `storageNamespace`, so its Keystore alias and preferences
  ///   are separate from the unbound slot's.
  /// - `requireBiometricsPerOperation` stays off: one prompt unwraps the
  ///   slot for the rest of the process, so write-then-read-back during
  ///   migration is one prompt, not three. A new process prompts again.
  factory FlutterSecureKeyStore.bound() => const FlutterSecureKeyStore(
    FlutterSecureStorage(
      iOptions: IOSOptions(
        // Its own Keychain service: items are unique by account + service,
        // so sharing the unbound slot's service would make adding the
        // bound copy fail as a duplicate of the unbound one.
        accountName: 'inner_flare_bound_key',
        accessibility: KeychainAccessibility.unlocked_this_device,
        accessControlFlags: [AccessControlFlag.userPresence],
      ),
      aOptions: AndroidOptions.biometric(
        storageNamespace: 'inner_flare_bound_key',
        enforceBiometrics: true,
        resetOnError: false,
        biometricType: AndroidBiometricType.biometricOrDeviceCredential,
        biometricPromptTitle: 'Unlock Inner Flare',
        biometricPromptSubtitle: 'Use your fingerprint, face, or screen lock',
      ),
    ),
  );

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _guard(() => _storage.read(key: key));

  @override
  Future<void> write(String key, String value) =>
      _guard(() => _storage.write(key: key, value: value));

  @override
  Future<void> delete(String key) => _guard(() => _storage.delete(key: key));

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PlatformException catch (e) {
      if (isAuthenticationFailure(e)) {
        throw KeyStoreAuthenticationFailed(e.message ?? e.code);
      }
      rethrow;
    }
  }
}
