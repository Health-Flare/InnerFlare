import 'package:inner_flare/core/security/db_passphrase_store.dart';
import 'package:inner_flare/core/security/screen_lock_probe.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'key_protection_provider.g.dart';

/// How the database key was protected the last time it was unlocked this
/// session; null until then (and in tests, screenshots and video mode,
/// which override `appDatabaseProvider`).
///
/// Set by `appDatabaseProvider` itself, so nothing that reads this ever
/// opens the database (see database_unlocked_provider.dart for why that
/// matters).
@Riverpod(keepAlive: true)
class KeyProtectionState extends _$KeyProtectionState {
  @override
  KeyProtection? build() => null;

  void set(KeyProtection? protection) => state = protection;
}

/// Whether to warn that anyone holding the phone can open the app: the
/// phone has no screen lock, or the last unlock this session found none.
/// False when it can't tell, so a probe hiccup never shows a scary
/// warning; the unlock itself fails closed on its own in that case.
@riverpod
bool showNoScreenLockWarning(Ref ref) {
  if (ref.watch(keyProtectionStateProvider) == KeyProtection.noScreenLock) {
    return true;
  }
  return ref.watch(phoneHasScreenLockProvider).value == false;
}

/// Shown on the unlock screen, the dashboard and Settings while the phone
/// has no screen lock (docs/features/unlock.feature).
const noScreenLockWarning =
    'This phone has no screen lock, so anyone holding it can open Inner '
    'Flare.';

/// Shown in Settings while the key is bound to the screen lock: turning
/// the lock off makes the key unreadable until it's turned back on.
const boundKeyExportAdvice =
    "Your data's key is tied to this phone's screen lock. Turning the "
    'screen lock off can delete that key, so export a backup first.';

/// The probe behind [phoneHasScreenLockProvider]; a provider so tests can
/// swap in a fake.
@riverpod
ScreenLockProbe screenLockProbe(Ref ref) => LocalAuthScreenLockProbe();

/// Whether the phone has a screen lock: true, false, or null when it
/// can't tell (including platforms with no `local_auth` at all, such as
/// the test runner). Never prompts, and never opens the database.
///
/// Only drives the "no screen lock" warning, so "can't tell" shows
/// nothing. The unlock itself never relies on this: it asks the probe
/// again and fails closed when it can't tell (see `DbPassphraseStore`).
@riverpod
Future<bool?> phoneHasScreenLock(Ref ref) async {
  try {
    return await ref.watch(screenLockProbeProvider).hasScreenLock();
  } on Object {
    return null;
  }
}
