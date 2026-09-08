import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inner_flare/core/providers/app_lock_provider.dart';
import 'package:inner_flare/core/providers/now_provider.dart';
import 'package:inner_flare/core/security/background_lock_policy.dart';
import 'package:inner_flare/features/security/screens/app_lock_screen.dart';

/// Wraps the whole app (via [MaterialApp.builder]) so that whatever screen
/// is on top gets covered by [AppLockScreen] once the app has spent
/// [backgroundLockTimeout] or more backgrounded — see
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
        if (backgroundedAt != null &&
            shouldRelockAfterBackground(
              backgroundedAt: backgroundedAt,
              resumedAt: now,
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
    return Stack(children: [widget.child, if (isLocked) const AppLockScreen()]);
  }
}
