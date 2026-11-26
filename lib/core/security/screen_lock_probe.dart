import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Whether the phone has a screen lock (passcode, PIN, pattern, password,
/// or biometrics, which need one of those anyway).
///
/// Throws when it can't tell. Callers must treat that as "stay locked and
/// let the user retry", never as "no screen lock": guessing "none" would
/// skip the protected key slot and hand out the unprotected one.
abstract class ScreenLockProbe {
  Future<bool> hasScreenLock();
}

/// [ScreenLockProbe] over `local_auth`'s `isDeviceSupported()`, which is
/// `canEvaluatePolicy(.deviceOwnerAuthentication)` on iOS (true exactly
/// when a passcode is set) and `KeyguardManager.isDeviceSecure() ||
/// canAuthenticateWithBiometrics()` on Android.
class LocalAuthScreenLockProbe implements ScreenLockProbe {
  LocalAuthScreenLockProbe({LocalAuthentication? auth})
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> hasScreenLock() => _auth.isDeviceSupported();
}

/// Thrown when [ScreenLockProbe] couldn't tell whether the phone has a
/// screen lock. Fails closed: the unlock screen shows its retry state.
class ScreenLockCheckFailure implements Exception {
  const ScreenLockCheckFailure(this.cause);

  final Object cause;

  @override
  String toString() =>
      "Couldn't check whether this phone has a screen lock, so your data "
      'stays locked. Tap Unlock to try again. ($cause)';
}

/// Whether this platform can hold the database key in the slot the OS
/// only releases after the user proves who they are.
abstract class KeyBindingSupport {
  Future<bool> isSupported();
}

/// Never binds: the caller-supplied `BiometricGate` is the unlock. For
/// tests, store screenshots and video mode, which open the real database
/// behind `AlwaysAllowBiometricGate` and must not show an OS prompt.
class NoKeyBinding implements KeyBindingSupport {
  const NoKeyBinding();

  @override
  Future<bool> isSupported() async => false;
}

/// iOS: always (Keychain `.userPresence`).
///
/// Android: 11 (API 30) and later only. On Android 9 and 10,
/// flutter_secure_storage can't let the screen lock unlock a key that
/// needs authentication for every use, so it binds the key to the
/// enrolled fingerprints alone: a phone with only a PIN couldn't create
/// it, and adding or removing a fingerprint would destroy it (and the
/// user's data with it). Those versions keep the unbound key behind the
/// `local_auth` prompt, as before.
///
/// Everything else (desktop, tests): no.
class PlatformKeyBindingSupport implements KeyBindingSupport {
  PlatformKeyBindingSupport({
    TargetPlatform? platform,
    Future<String?> Function()? androidRelease,
  }) : _platform = platform ?? defaultTargetPlatform,
       _androidRelease = androidRelease ?? _sqfliteAndroidRelease;

  final TargetPlatform _platform;
  final Future<String?> Function() _androidRelease;

  @override
  Future<bool> isSupported() async {
    if (kIsWeb) return false;
    switch (_platform) {
      case TargetPlatform.iOS:
        return true;
      case TargetPlatform.android:
        final major = androidMajorVersion(await _androidRelease());
        return major != null && major >= 11;
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return false;
    }
  }
}

/// The leading major version from an Android release string like
/// "Android 11", "Android 12", or "Android 8.1.0". Null when there isn't
/// one (e.g. a preview build named "Android Tiramisu"): callers treat that
/// as "not supported", the safe direction.
int? androidMajorVersion(String? release) {
  if (release == null) return null;
  final match = RegExp(r'^Android (\d+)').firstMatch(release.trim());
  return match == null ? null : int.tryParse(match.group(1)!);
}

/// The Android release, via the SQLCipher plugin the app already ships
/// (`"Android " + Build.VERSION.RELEASE`), rather than a new dependency or
/// a native channel. Any failure reads as "unknown", which keeps the old,
/// prompt-first path.
Future<String?> _sqfliteAndroidRelease() async {
  if (!Platform.isAndroid) return null;
  try {
    return await const MethodChannel(
      'com.davidmartos96.sqflite_sqlcipher',
    ).invokeMethod<String>('getPlatformVersion');
  } on Exception {
    return null;
  }
}
