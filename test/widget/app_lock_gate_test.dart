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

      expect(find.text('InnerFlare is locked'), findsNothing);
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

      expect(find.text('InnerFlare is locked'), findsOneWidget);
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

      await tester.tap(find.text('Unlock'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('InnerFlare is locked'), findsOneWidget);
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

      await tester.tap(find.text('Unlock'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('InnerFlare is locked'), findsNothing);
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
        expect(find.text('InnerFlare is locked'), findsOneWidget);

        // Tapping Unlock starts an authentication attempt that won't
        // resolve until we complete it below — standing in for the native
        // prompt being on screen.
        await tester.tap(find.text('Unlock'));
        await tester.pump();

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
        expect(find.text('InnerFlare is locked'), findsNothing);

        // ...but the prompt's own dismissal resolves to `resumed` on the
        // app's lifecycle independently of (and here, after) that result.
        // Before the fix, this was mistaken for a real backgrounding and,
        // with "Immediately" configured, re-locked the app right back —
        // the unlock loop force-closing was the only escape from.
        WidgetsBinding.instance.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();

        expect(find.text('InnerFlare is locked'), findsNothing);
        expect(find.text('dashboard content'), findsOneWidget);
      },
    );
  });
}
