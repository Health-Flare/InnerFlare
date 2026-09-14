import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'database_unlocked_provider.g.dart';

/// Whether the encrypted database has been opened at least once this
/// session — set by `AppUnlockGate` once `appDatabaseProvider` resolves.
///
/// Exists so other code that needs to know "has the user unlocked yet"
/// (namely `AppLockGate`, which wants to eagerly warm
/// docs/features/app_lock.feature's timeout setting) can check without
/// itself watching `appDatabaseProvider` or anything backed by it —
/// watching either would open the database, bypassing
/// docs/features/unlock.feature's "nothing is touched until the user taps
/// Unlock" rule through a side door. This was a real bug: `AppLockGate`
/// watches `lockTimeoutProvider` unconditionally on every build (see its
/// own docs), and `lockTimeoutProvider` reads its setting from the
/// database — so that single unconditional watch, needed from the very
/// first frame (`AppLockGate` wraps the whole app via
/// `MaterialApp.builder`), was silently triggering the biometric prompt
/// before the user ever saw — let alone tapped — the unlock screen.
@Riverpod(keepAlive: true)
class DatabaseUnlocked extends _$DatabaseUnlocked {
  @override
  bool build() => false;

  void markUnlocked() => state = true;
}
