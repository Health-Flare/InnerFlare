import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inner_flare/core/providers/database_provider.dart';
import 'package:inner_flare/core/providers/database_unlocked_provider.dart';
import 'package:inner_flare/features/dashboard/widgets/database_status_indicator.dart';
import 'package:inner_flare/features/security/screens/app_unlock_screen.dart';

/// Shows [AppUnlockScreen] in place of [child] until the encrypted
/// database is open — first open of a session, or a retry after a failure
/// (docs/features/unlock.feature) — instead of letting the dashboard flash
/// partially loaded behind a diagnostic AppBar icon/banner.
///
/// `appDatabaseProvider` is never watched until the user taps "Unlock":
/// watching it is what triggers `AppDatabase().open()`'s biometric/passcode
/// prompt, and firing that automatically — even after a short delay — can
/// still visually race whatever page transition brought this screen on
/// screen, so the user never gets a legible moment of the app's own
/// branding before a system prompt appears on top of it. An explicit tap
/// sidesteps that entirely, and means the encrypted database is never even
/// created until the user has chosen to unlock it.
///
/// [child] itself isn't built until the database is actually open, unlike
/// `AppLockGate`'s "cover, don't remove" pattern for idle re-locking:
/// there's no prior on-screen state to preserve for a first open, and
/// [child] (the dashboard) has its own widgets that independently watch
/// `appDatabaseProvider` (see `DatabaseStatusIndicator`) — building it
/// early would trigger the same prompt through a side door.
class AppUnlockGate extends ConsumerStatefulWidget {
  const AppUnlockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppUnlockGate> createState() => _AppUnlockGateState();
}

class _AppUnlockGateState extends ConsumerState<AppUnlockGate> {
  bool _unlockRequested = false;

  @override
  Widget build(BuildContext context) {
    if (!_unlockRequested) {
      return AppUnlockScreen(
        busy: false,
        failed: false,
        onUnlock: () => setState(() => _unlockRequested = true),
      );
    }

    // Side effect, not a value read — see database_unlocked_provider.dart
    // for why AppLockGate needs this rather than watching the database
    // chain itself. ref.listen (not ref.watch) so this doesn't add a
    // second reason for this widget to rebuild.
    ref.listen(appDatabaseProvider, (previous, next) {
      if (next.hasValue) {
        ref.read(databaseUnlockedProvider.notifier).markUnlocked();
      }
    });
    final dbAsync = ref.watch(appDatabaseProvider);
    if (dbAsync.hasValue) {
      return widget.child;
    }
    return AppUnlockScreen(
      busy: dbAsync.isLoading,
      failed: dbAsync.hasError,
      onUnlock: dbAsync.hasError ? () => retryDatabaseUnlock(ref) : null,
    );
  }
}
