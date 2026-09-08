import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/core/providers/biometric_gate_provider.dart';
import 'package:inner_flare/core/providers/now_provider.dart';
import 'package:inner_flare/core/security/app_lock_gate.dart';
import 'package:inner_flare/core/security/biometric_gate.dart';

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
  });
}
