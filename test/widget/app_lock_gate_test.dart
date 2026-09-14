import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/core/providers/biometric_gate_provider.dart';
import 'package:inner_flare/core/providers/lock_timeout_provider.dart';
import 'package:inner_flare/core/providers/now_provider.dart';
import 'package:inner_flare/core/security/app_lock_gate.dart';
import 'package:inner_flare/core/security/biometric_gate.dart';
import 'package:inner_flare/models/lock_timeout.dart';

/// A settable clock, so tests can move "now" forward without waiting.
class _FakeClock {
  _FakeClock(this._now);
  DateTime _now;
  DateTime call() => _now;
  void advanceBy(Duration duration) => _now = _now.add(duration);
}

class _FixedResultGate implements BiometricGate {
  _FixedResultGate(this.result);
  final bool result;
  @override
  Future<bool> authenticate() async => result;
}

/// A gate whose authenticate() doesn't resolve until [complete] is called,
/// so tests can fire lifecycle events while an authentication attempt is
/// still in flight — mimicking the native biometric/passcode prompt being
/// on screen.
class _ControllableGate implements BiometricGate {
  final _completer = Completer<bool>();
  @override
  Future<bool> authenticate() => _completer.future;
  void complete(bool result) => _completer.complete(result);
}

class _FixedLockTimeoutNotifier extends LockTimeoutNotifier {
  _FixedLockTimeoutNotifier(this.value);
  final LockTimeout value;
  @override
  Future<LockTimeout> build() async => value;
}

/// Records every authenticate() call and lets each be resolved
/// individually, in order — so a test can tell an automatically-triggered
/// first attempt apart from a manually-retried one (docs/features/unlock.feature).
class _CountingGate implements BiometricGate {
  int callCount = 0;
  final _pending = <Completer<bool>>[];

  @override
  Future<bool> authenticate() {
    callCount++;
    final completer = Completer<bool>();
    _pending.add(completer);
    return completer.future;
  }

  void completeNext(bool result) {
    if (_pending.isEmpty) {
      throw StateError(
        'No authenticate() call is pending — the lock screen never '
        'triggered one automatically.',
      );
    }
    _pending.removeAt(0).complete(result);
  }
}

void main() {
  group('AppLockGate', () {
    testWidgets('a brief background does not show the lock screen', (
      tester,
    ) async {
      final clock = _FakeClock(DateTime(2026, 1, 1, 12));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [nowProvider.overrideWithValue(clock.call)],
          child: MaterialApp(
            builder: (context, child) => AppLockGate(child: child!),
            home: const Scaffold(body: Text('dashboard content')),
          ),
        ),
      );

      WidgetsBinding.instance.handleAppLifecycleStateChanged(
        AppLifecycleState.paused,
      );
      clock.advanceBy(const Duration(minutes: 5));
      WidgetsBinding.instance.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      );
      await tester.pump();

      expect(find.text('Inner Flare is locked'), findsNothing);
      expect(find.text('dashboard content'), findsOneWidget);
    });

    testWidgets('15 minutes or more backgrounded shows the lock screen over '
        'whatever was on screen', (tester) async {
      final clock = _FakeClock(DateTime(2026, 1, 1, 12));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [nowProvider.overrideWithValue(clock.call)],
          child: MaterialApp(
            builder: (context, child) => AppLockGate(child: child!),
            home: const Scaffold(body: Text('dashboard content')),
          ),
        ),
      );

      WidgetsBinding.instance.handleAppLifecycleStateChanged(
        AppLifecycleState.paused,
      );
      clock.advanceBy(const Duration(minutes: 15));
      WidgetsBinding.instance.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      );
      await tester.pump();

      expect(find.text('Inner Flare is locked'), findsOneWidget);
      // The underlying content is still there — just covered — so
      // nothing downstream needs to know it might be locked.
      expect(find.text('dashboard content'), findsOneWidget);
    });

    testWidgets('cancelling re-authentication leaves the lock screen up', (
      tester,
    ) async {
      final clock = _FakeClock(DateTime(2026, 1, 1, 12));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            nowProvider.overrideWithValue(clock.call),
            biometricGateProvider.overrideWithValue(_FixedResultGate(false)),
          ],
          child: MaterialApp(
            builder: (context, child) => AppLockGate(child: child!),
            home: const Scaffold(body: Text('dashboard content')),
          ),
        ),
      );

      WidgetsBinding.instance.handleAppLifecycleStateChanged(
        AppLifecycleState.paused,
      );
      clock.advanceBy(const Duration(minutes: 15));
      WidgetsBinding.instance.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      );
      await tester.pump();
      // The lock screen triggers authentication itself as soon as it
      // appears — no tap needed for this first attempt (docs/features/unlock.feature).
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Inner Flare is locked'), findsOneWidget);
    });

    testWidgets('successful re-authentication dismisses the lock screen', (
      tester,
    ) async {
      final clock = _FakeClock(DateTime(2026, 1, 1, 12));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            nowProvider.overrideWithValue(clock.call),
            biometricGateProvider.overrideWithValue(_FixedResultGate(true)),
          ],
          child: MaterialApp(
            builder: (context, child) => AppLockGate(child: child!),
            home: const Scaffold(body: Text('dashboard content')),
          ),
        ),
      );

      WidgetsBinding.instance.handleAppLifecycleStateChanged(
        AppLifecycleState.paused,
      );
      clock.advanceBy(const Duration(minutes: 15));
      WidgetsBinding.instance.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      );
      await tester.pump();
      // Auto-triggered, no tap needed (docs/features/unlock.feature).
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Inner Flare is locked'), findsNothing);
      expect(find.text('dashboard content'), findsOneWidget);
    });

    testWidgets(
      "the biometric prompt's own inactive/resumed transition doesn't "
      're-lock a successful unlock (regression for the unlock loop)',
      (tester) async {
        final clock = _FakeClock(DateTime(2026, 1, 1, 12));
        final gate = _ControllableGate();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              nowProvider.overrideWithValue(clock.call),
              biometricGateProvider.overrideWithValue(gate),
              lockTimeoutProvider.overrideWith(
                () => _FixedLockTimeoutNotifier(LockTimeout.immediately),
              ),
            ],
            child: MaterialApp(
              builder: (context, child) => AppLockGate(child: child!),
              home: const Scaffold(body: Text('dashboard content')),
            ),
          ),
        );
        await tester.pump();

        // Any backgrounding at all re-locks on the "Immediately" setting.
        WidgetsBinding.instance.handleAppLifecycleStateChanged(
          AppLifecycleState.paused,
        );
        WidgetsBinding.instance.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();
        expect(find.text('Inner Flare is locked'), findsOneWidget);

        // The lock screen has already triggered authentication itself, as
        // soon as it appeared — no tap needed. It won't resolve until we
        // complete it below, standing in for the native prompt being on
        // screen.
        await tester.pump(const Duration(milliseconds: 50));

        // Presenting that prompt itself takes the app through `inactive` —
        // exactly what Face ID's system sheet (or Android's separate
        // device-credential activity for a manual passcode) does, even
        // though the user never left the app.
        WidgetsBinding.instance.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );

        // The authentication succeeds and AppLockScreen unlocks the app...
        gate.complete(true);
        await tester.pump();
        expect(find.text('Inner Flare is locked'), findsNothing);

        // ...but the prompt's own dismissal resolves to `resumed` on the
        // app's lifecycle independently of (and here, after) that result.
        // Before the fix, this was mistaken for a real backgrounding and,
        // with "Immediately" configured, re-locked the app right back —
        // the unlock loop force-closing was the only escape from.
        WidgetsBinding.instance.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();

        expect(find.text('Inner Flare is locked'), findsNothing);
        expect(find.text('dashboard content'), findsOneWidget);
      },
    );

    // --- docs/features/unlock.feature: the lock screen should prompt for
    // itself, and only itself — no tap for the first attempt, no
    // auto-retry after a cancel, no double prompt on a retry tap. ---

    testWidgets(
      'the unlock prompt fires automatically as soon as the lock screen '
      'appears, with no tap',
      (tester) async {
        final clock = _FakeClock(DateTime(2026, 1, 1, 12));
        final gate = _CountingGate();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              nowProvider.overrideWithValue(clock.call),
              biometricGateProvider.overrideWithValue(gate),
            ],
            child: MaterialApp(
              builder: (context, child) => AppLockGate(child: child!),
              home: const Scaffold(body: Text('dashboard content')),
            ),
          ),
        );

        WidgetsBinding.instance.handleAppLifecycleStateChanged(
          AppLifecycleState.paused,
        );
        clock.advanceBy(const Duration(minutes: 15));
        WidgetsBinding.instance.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();
        // Give any auto-triggered authentication a moment to start —
        // note there is no tester.tap() anywhere in this test.
        await tester.pump(const Duration(milliseconds: 50));

        expect(
          gate.callCount,
          1,
          reason:
              'the lock screen should trigger authentication itself as '
              'soon as it appears, not wait for a tap on "Unlock"',
        );
      },
    );

    testWidgets('cancelling the automatic prompt leaves a single manual retry, '
        'without auto-retrying on its own', (tester) async {
      final clock = _FakeClock(DateTime(2026, 1, 1, 12));
      final gate = _CountingGate();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            nowProvider.overrideWithValue(clock.call),
            biometricGateProvider.overrideWithValue(gate),
          ],
          child: MaterialApp(
            builder: (context, child) => AppLockGate(child: child!),
            home: const Scaffold(body: Text('dashboard content')),
          ),
        ),
      );

      WidgetsBinding.instance.handleAppLifecycleStateChanged(
        AppLifecycleState.paused,
      );
      clock.advanceBy(const Duration(minutes: 15));
      WidgetsBinding.instance.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // The automatically-triggered attempt is cancelled.
      gate.completeNext(false);
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Inner Flare is locked'), findsOneWidget);
      expect(find.text('Unlock'), findsOneWidget);

      // Sitting on the cancelled screen must never spontaneously trigger
      // a second prompt — only a tap on "Unlock" should.
      await tester.pump(const Duration(seconds: 5));
      expect(gate.callCount, 1);
    });

    testWidgets(
      'retrying after a cancelled automatic prompt is a single tap, not '
      'a stack of prompts',
      (tester) async {
        final clock = _FakeClock(DateTime(2026, 1, 1, 12));
        final gate = _CountingGate();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              nowProvider.overrideWithValue(clock.call),
              biometricGateProvider.overrideWithValue(gate),
            ],
            child: MaterialApp(
              builder: (context, child) => AppLockGate(child: child!),
              home: const Scaffold(body: Text('dashboard content')),
            ),
          ),
        );

        WidgetsBinding.instance.handleAppLifecycleStateChanged(
          AppLifecycleState.paused,
        );
        clock.advanceBy(const Duration(minutes: 15));
        WidgetsBinding.instance.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        gate.completeNext(false);
        await tester.pump(const Duration(milliseconds: 50));

        await tester.tap(find.text('Unlock'));
        await tester.pump();

        expect(
          gate.callCount,
          2,
          reason: 'one tap on "Unlock" should trigger exactly one new prompt',
        );

        gate.completeNext(true);
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.text('Inner Flare is locked'), findsNothing);
        expect(find.text('dashboard content'), findsOneWidget);
      },
    );
  });
}
