import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reauthenticating_provider.g.dart';

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
@Riverpod(keepAlive: true)
ReauthenticationFlag reauthenticationFlag(Ref ref) => ReauthenticationFlag();

class ReauthenticationFlag {
  bool inProgress = false;
}
