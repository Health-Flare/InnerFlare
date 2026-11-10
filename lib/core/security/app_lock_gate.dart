import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inner_flare/core/providers/app_lock_provider.dart';
import 'package:inner_flare/core/providers/database_unlocked_provider.dart';
import 'package:inner_flare/core/providers/lock_timeout_provider.dart';
import 'package:inner_flare/core/providers/now_provider.dart';
import 'package:inner_flare/core/providers/reauthenticating_provider.dart';
import 'package:inner_flare/core/security/background_lock_policy.dart';
import 'package:inner_flare/features/security/screens/app_lock_screen.dart';
import 'package:inner_flare/models/lock_timeout.dart';

/// Wraps the whole app (via [MaterialApp.builder]) so that whatever screen
/// is on top is replaced by [AppLockScreen] once the app has spent the
/// user's configured [LockTimeout] or more backgrounded; see
/// docs/features/app_lock.feature.
///
/// While locked, the wrapped [child] stays mounted (so a half-written
/// note survives the lock) but is offstage (not painted, not
/// hit-testable), excluded from semantics (so TalkBack, VoiceOver or an
/// accessibility service can't read it, issue #91), excluded from focus
/// (so a hardware keyboard can't type into it) and has its tickers
/// paused. The wrappers are always in the tree, whatever the lock state,
/// so locking never rebuilds [child] from scratch.
///
/// The snapshot the OS takes for the app switcher is covered natively,
/// not here: by the time Dart hears about `inactive` the snapshot may
/// already be taken. See ios/Runner/SceneDelegate.swift and
/// android/app/src/main/kotlin/.../MainActivity.kt.
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate>
    with WidgetsBindingObserver {
  DateTime? _backgroundedAt;

  /// The last lifecycle state seen, so a state can be read as a step
  /// away from the screen or a step back. Android and iOS report the
  /// same states both ways (resumed > inactive > hidden > paused on the
  /// way out, the reverse on the way back), so `hidden` on its own
  /// doesn't say which way the app is going.
  AppLifecycleState _lastState =
      WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;

  /// How far from the screen each state is. Higher is further away.
  static int _depth(AppLifecycleState state) => switch (state) {
    AppLifecycleState.resumed => 0,
    AppLifecycleState.inactive => 1,
    AppLifecycleState.hidden => 2,
    AppLifecycleState.paused => 3,
    AppLifecycleState.detached => 4,
  };

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
    final previous = _lastState;
    _lastState = state;
    final leaving = _depth(state) > _depth(previous);
    if (ref.read(reauthenticationFlagProvider).inProgress) {
      // AppLockScreen's own biometric/passcode prompt is what's causing
      // this transition (system sheet, or Android's separate
      // device-credential activity for a manual passcode), not the user
      // actually backgrounding the app. Treating it as a real
      // backgrounding here would race with (and can undo) the unlock
      // attempt already in flight; see reauthenticating_provider.dart.
      return;
    }
    if (!ref.read(databaseUnlockedProvider)) {
      // Nothing has been unlocked this session yet, so AppUnlockGate's
      // unlock screen is already up and there is nothing to cover. Its
      // own first biometric prompt also causes these transitions;
      // counting them as time away would lock the app the moment that
      // first unlock succeeds.
      return;
    }
    final now = ref.read(nowProvider)();
    // Falls back to the default timeout if the setting hasn't loaded
    // yet: the setting lives behind the same encrypted database as
    // everything else, so there's nothing more sensitive to protect by
    // waiting on it here; defaulting keeps this check working even
    // before that read resolves.
    final timeout =
        ref.read(lockTimeoutProvider).value?.duration ??
        LockTimeout.defaultValue.duration;
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        // Steps back towards the screen (paused > hidden > inactive) are
        // not time away; the resumed that follows them decides.
        if (!leaving) break;
        // Only record the first step away: a hop from resumed straight to
        // paused (or back and forth through inactive/hidden on the way
        // out) shouldn't reset the clock partway through leaving.
        _backgroundedAt ??= now;
        // "Immediately": lock as soon as the app is actually off screen,
        // so the first frame on return is the lock screen rather than a
        // frame of stale content (issue #91). Not on `inactive`, which
        // also covers a pulled-down notification shade or control centre
        // with the app still showing; that case still locks on return.
        if (timeout == Duration.zero && state != AppLifecycleState.inactive) {
          ref.read(appLockProvider.notifier).lock();
          // Flutter stops scheduling frames once hidden/paused, so without
          // this the lock screen wouldn't be drawn until the app is back
          // and the last frame on the surface would still be the screen
          // underneath. Best effort: the platform may not draw it while
          // backgrounded. The native covers handle the app switcher.
          SchedulerBinding.instance.scheduleForcedFrame();
        }
      case AppLifecycleState.resumed:
        final backgroundedAt = _backgroundedAt;
        _backgroundedAt = null;
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
    // time didChangeAppLifecycleState needs it: this widget stays
    // mounted for the app's whole lifetime, so watching here keeps the
    // otherwise-autoDispose provider alive throughout. Gated on
    // databaseUnlockedProvider (a plain in-memory flag, not anything
    // database-backed): lockTimeoutProvider reads from the database, and
    // this widget mounts on the very first frame: watching it
    // unconditionally used to open the database itself, before the user
    // had even seen the unlock screen, let alone tapped it (see
    // database_unlocked_provider.dart).
    if (ref.watch(databaseUnlockedProvider)) {
      ref.watch(lockTimeoutProvider);
    }
    // Drop keyboard focus the moment the lock goes up, so the software
    // keyboard closes and nothing typed lands in a covered note field.
    ref.listen(appLockProvider, (wasLocked, nowLocked) {
      if (nowLocked && wasLocked != true) {
        FocusManager.instance.primaryFocus?.unfocus();
      }
    });
    return Stack(
      children: [
        ExcludeSemantics(
          excluding: isLocked,
          child: ExcludeFocus(
            excluding: isLocked,
            child: TickerMode(
              enabled: !isLocked,
              child: Offstage(offstage: isLocked, child: widget.child),
            ),
          ),
        ),
        if (isLocked) const AppLockScreen(),
      ],
    );
  }
}
