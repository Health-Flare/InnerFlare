import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inner_flare/core/providers/app_lock_provider.dart';
import 'package:inner_flare/core/providers/lock_timeout_provider.dart';
import 'package:inner_flare/core/providers/now_provider.dart';
import 'package:inner_flare/core/providers/reauthenticating_provider.dart';
import 'package:inner_flare/core/security/background_lock_policy.dart';
import 'package:inner_flare/features/security/screens/app_lock_screen.dart';
import 'package:inner_flare/models/lock_timeout.dart';

/// Wraps the whole app (via [MaterialApp.builder]) so that whatever screen
/// is on top gets covered by [AppLockScreen] once the app has spent the
/// user's configured [LockTimeout] or more backgrounded — see
/// docs/features/app_lock.feature. The wrapped [child] keeps running
/// underneath; it's just visually and interactively covered, so nothing
/// needs to know it might be locked.
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate>
    with WidgetsBindingObserver {
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (ref.read(reauthenticationFlagProvider).inProgress) {
      // AppLockScreen's own biometric/passcode prompt is what's causing
      // this transition (system sheet, or Android's separate
      // device-credential activity for a manual passcode) — not the user
      // actually backgrounding the app. Treating it as a real
      // backgrounding here would race with (and can undo) the unlock
      // attempt already in flight — see reauthenticating_provider.dart.
      return;
    }
    final now = ref.read(nowProvider)();
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        // Only record the first step away — a hop from resumed straight to
        // paused (or back and forth through inactive/hidden on the way
        // out) shouldn't reset the clock partway through leaving.
        _backgroundedAt ??= now;
      case AppLifecycleState.resumed:
        final backgroundedAt = _backgroundedAt;
        _backgroundedAt = null;
        // Falls back to the default timeout if the setting hasn't loaded
        // yet — the setting lives behind the same encrypted database as
        // everything else, so there's nothing more sensitive to protect
        // by waiting on it here; defaulting keeps this check working even
        // before that read resolves.
        final timeout =
            ref.read(lockTimeoutProvider).value?.duration ??
            LockTimeout.defaultValue.duration;
        if (backgroundedAt != null &&
            shouldRelockAfterBackground(
              backgroundedAt: backgroundedAt,
              resumedAt: now,
              timeout: timeout,
            )) {
          ref.read(appLockProvider.notifier).lock();
        }
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = ref.watch(appLockProvider);
    // Watched (not just read) so the setting is already loaded by the
    // time didChangeAppLifecycleState needs it — this widget stays
    // mounted for the app's whole lifetime, so watching here keeps the
    // otherwise-autoDispose provider alive throughout.
    ref.watch(lockTimeoutProvider);
    return Stack(children: [widget.child, if (isLocked) const AppLockScreen()]);
  }
}
