import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/core/providers/biometric_gate_provider.dart';
import 'package:inner_flare/core/providers/database_unlocked_provider.dart';
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
/// still in flight, mimicking the native biometric/passcode prompt being
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

/// A setting that hasn't finished loading yet, so AppLockGate falls back
/// to [LockTimeout.defaultValue]. Also keeps these tests off the real
/// database.
class _PendingLockTimeoutNotifier extends LockTimeoutNotifier {
  @override
  Future<LockTimeout> build() => Completer<LockTimeout>().future;
}

/// AppLockGate only eagerly warms lockTimeoutProvider once
/// databaseUnlockedProvider is true (database_unlocked_provider.dart),
/// which in the real app is only ever the case once the user has already
/// unlocked once via AppUnlockGate. Tests that exercise idle re-lock
/// (rather than the unlock gating itself) need to represent that
/// already-unlocked precondition explicitly.
class _AlreadyUnlocked extends DatabaseUnlocked {
  @override
  bool build() => true;
}

void _lifecycle(AppLifecycleState state) {
  WidgetsBinding.instance.handleAppLifecycleStateChanged(state);
}

/// The full sequence a phone reports when the app goes to the background
/// (home gesture, app switcher, another app on top). Some widgets (any
/// TextField) assert that transitions follow it.
void _leave() {
  _lifecycle(AppLifecycleState.inactive);
  _lifecycle(AppLifecycleState.hidden);
  _lifecycle(AppLifecycleState.paused);
}

/// The full sequence on coming back.
void _comeBack() {
  _lifecycle(AppLifecycleState.hidden);
  _lifecycle(AppLifecycleState.inactive);
  _lifecycle(AppLifecycleState.resumed);
}

/// Every label and value in the live semantics tree: the same tree
/// TalkBack, VoiceOver and any Android accessibility service read from.
List<String> _semanticsText(WidgetTester tester) {
  final text = <String>[];
  void visit(SemanticsNode node) {
    if (node.label.isNotEmpty) text.add(node.label);
    if (node.value.isNotEmpty) text.add(node.value);
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  void visitOwner(PipelineOwner owner) {
    final root = owner.semanticsOwner?.rootSemanticsNode;
    if (root != null) visit(root);
    owner.visitChildren(visitOwner);
  }

  visitOwner(tester.binding.rootPipelineOwner);
  return text;
}

void main() {
  late _FakeClock clock;

  setUp(() => clock = _FakeClock(DateTime(2026, 1, 1, 12)));

  /// Pumps [home] under AppLockGate. [timeout] null leaves the setting
  /// unloaded, so the gate falls back to [LockTimeout.defaultValue].
  Future<void> pumpGate(
    WidgetTester tester, {
    Widget home = const Scaffold(body: Text('dashboard content')),
    LockTimeout? timeout,
    BiometricGate? gate,
    bool alreadyUnlocked = true,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          nowProvider.overrideWithValue(clock.call),
          if (gate != null) biometricGateProvider.overrideWithValue(gate),
          if (alreadyUnlocked)
            databaseUnlockedProvider.overrideWith(_AlreadyUnlocked.new),
          lockTimeoutProvider.overrideWith(
            () => timeout == null
                ? _PendingLockTimeoutNotifier()
                : _FixedLockTimeoutNotifier(timeout),
          ),
        ],
        child: MaterialApp(
          builder: (context, child) => AppLockGate(child: child!),
          home: home,
        ),
      ),
    );
    await tester.pump();
  }

  group('AppLockGate', () {
    testWidgets('a brief background does not show the lock screen', (
      tester,
    ) async {
      await pumpGate(tester);

      _leave();
      clock.advanceBy(const Duration(seconds: 30));
      _comeBack();
      await tester.pump();

      expect(find.text('Inner Flare is locked'), findsNothing);
      expect(find.text('dashboard content'), findsOneWidget);
    });

    testWidgets('the default timeout (1 minute) backgrounded shows the lock '
        'screen in place of whatever was on screen', (tester) async {
      await pumpGate(tester);

      _leave();
      clock.advanceBy(const Duration(minutes: 1));
      _comeBack();
      await tester.pump();

      expect(find.text('Inner Flare is locked'), findsOneWidget);
      // The screen underneath is still mounted, so its state survives
      // the lock, but it's offstage: not painted and not hit-testable.
      expect(find.text('dashboard content'), findsNothing);
      expect(
        find.text('dashboard content', skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('a saved 15 minute timeout still waits 15 minutes '
        '(regression guard)', (tester) async {
      await pumpGate(tester, timeout: LockTimeout.after15Minutes);

      _leave();
      clock.advanceBy(const Duration(minutes: 14));
      _comeBack();
      await tester.pump();
      expect(find.text('Inner Flare is locked'), findsNothing);

      _leave();
      clock.advanceBy(const Duration(minutes: 15));
      _comeBack();
      await tester.pump();
      expect(find.text('Inner Flare is locked'), findsOneWidget);
    });

    testWidgets('cancelling re-authentication leaves the lock screen up', (
      tester,
    ) async {
      await pumpGate(tester, gate: _FixedResultGate(false));

      _leave();
      clock.advanceBy(const Duration(minutes: 15));
      _comeBack();
      await tester.pump();

      await tester.tap(find.text('Unlock'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Inner Flare is locked'), findsOneWidget);
    });

    testWidgets('successful re-authentication dismisses the lock screen', (
      tester,
    ) async {
      await pumpGate(tester, gate: _FixedResultGate(true));

      _leave();
      clock.advanceBy(const Duration(minutes: 15));
      _comeBack();
      await tester.pump();

      await tester.tap(find.text('Unlock'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Inner Flare is locked'), findsNothing);
      expect(find.text('dashboard content'), findsOneWidget);
    });

    testWidgets(
      "the biometric prompt's own inactive/resumed transition doesn't "
      're-lock a successful unlock (regression for the unlock loop)',
      (tester) async {
        final gate = _ControllableGate();
        await pumpGate(tester, gate: gate, timeout: LockTimeout.immediately);

        // Any backgrounding at all re-locks on the "Immediately" setting.
        _lifecycle(AppLifecycleState.paused);
        _lifecycle(AppLifecycleState.resumed);
        await tester.pump();
        expect(find.text('Inner Flare is locked'), findsOneWidget);

        // Tapping Unlock starts an authentication attempt that won't
        // resolve until we complete it below, standing in for the native
        // prompt being on screen.
        await tester.tap(find.text('Unlock'));
        await tester.pump();

        // Presenting that prompt itself takes the app through `inactive`,
        // exactly what Face ID's system sheet (or Android's separate
        // device-credential activity for a manual passcode) does, even
        // though the user never left the app.
        _lifecycle(AppLifecycleState.inactive);

        // The authentication succeeds and AppLockScreen unlocks the app...
        gate.complete(true);
        await tester.pump();
        expect(find.text('Inner Flare is locked'), findsNothing);

        // ...but the prompt's own dismissal resolves to `resumed` on the
        // app's lifecycle independently of (and here, after) that result.
        // Before the fix, this was mistaken for a real backgrounding and,
        // with "Immediately" configured, re-locked the app right back:
        // the unlock loop force-closing was the only escape from.
        _lifecycle(AppLifecycleState.resumed);
        await tester.pump();

        expect(find.text('Inner Flare is locked'), findsNothing);
        expect(find.text('dashboard content'), findsOneWidget);
      },
    );
  });

  group('AppLockGate, "Immediately" (issue #91)', () {
    for (final state in [AppLifecycleState.paused, AppLifecycleState.hidden]) {
      testWidgets('locks on ${state.name}, before the app comes back', (
        tester,
      ) async {
        await pumpGate(tester, timeout: LockTimeout.immediately);

        _lifecycle(AppLifecycleState.inactive);
        _lifecycle(AppLifecycleState.hidden);
        if (state == AppLifecycleState.paused) _lifecycle(state);
        await tester.pump();

        // No resumed yet: the lock is already up, so the first frame on
        // return is the lock screen, not stale content.
        expect(find.text('Inner Flare is locked'), findsOneWidget);
        expect(find.text('dashboard content'), findsNothing);
      });
    }

    testWidgets('inactive alone (control centre, notification shade) does '
        'not lock (regression guard)', (tester) async {
      await pumpGate(tester, timeout: LockTimeout.immediately);

      _lifecycle(AppLifecycleState.inactive);
      await tester.pump();

      expect(find.text('Inner Flare is locked'), findsNothing);
    });

    testWidgets('a timed setting does not lock on paused, only on return '
        '(regression guard)', (tester) async {
      await pumpGate(tester, timeout: LockTimeout.after5Minutes);

      _lifecycle(AppLifecycleState.inactive);
      _lifecycle(AppLifecycleState.hidden);
      _lifecycle(AppLifecycleState.paused);
      await tester.pump();

      expect(find.text('Inner Flare is locked'), findsNothing);
    });

    testWidgets("Android's passcode screen pausing the app during an unlock "
        'attempt does not relock it', (tester) async {
      final gate = _ControllableGate();
      await pumpGate(tester, gate: gate, timeout: LockTimeout.immediately);

      _leave();
      _comeBack();
      await tester.pump();
      expect(find.text('Inner Flare is locked'), findsOneWidget);

      await tester.tap(find.text('Unlock'));
      await tester.pump();

      // The device-credential activity covers the app completely, so
      // Android reports the full inactive > hidden > paused sequence.
      _lifecycle(AppLifecycleState.inactive);
      _lifecycle(AppLifecycleState.hidden);
      _lifecycle(AppLifecycleState.paused);
      await tester.pump();

      gate.complete(true);
      await tester.pump();

      _lifecycle(AppLifecycleState.hidden);
      _lifecycle(AppLifecycleState.inactive);
      _lifecycle(AppLifecycleState.resumed);
      await tester.pump();

      expect(find.text('Inner Flare is locked'), findsNothing);
      expect(find.text('dashboard content'), findsOneWidget);
    });

    testWidgets('before the first unlock of the session nothing locks: the '
        "unlock screen is already up, and that first unlock's own prompt "
        'must not count as time away', (tester) async {
      await pumpGate(
        tester,
        timeout: LockTimeout.immediately,
        alreadyUnlocked: false,
      );

      _lifecycle(AppLifecycleState.inactive);
      _lifecycle(AppLifecycleState.hidden);
      _lifecycle(AppLifecycleState.paused);
      clock.advanceBy(const Duration(hours: 2));
      _lifecycle(AppLifecycleState.hidden);
      _lifecycle(AppLifecycleState.inactive);
      _lifecycle(AppLifecycleState.resumed);
      await tester.pump();

      expect(find.text('Inner Flare is locked'), findsNothing);
    });
  });

  group('AppLockGate, what the lock hides (issue #91)', () {
    Future<void> lockNow(WidgetTester tester) async {
      _leave();
      await tester.pump();
      expect(find.text('Inner Flare is locked'), findsOneWidget);
    }

    testWidgets('screen readers and accessibility services cannot read the '
        'screen underneath', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpGate(tester, timeout: LockTimeout.immediately);

      // The walk does see real content before the lock.
      expect(_semanticsText(tester), contains('dashboard content'));

      await lockNow(tester);

      final text = _semanticsText(tester);
      expect(
        text.where((t) => t.contains('Inner Flare is locked')),
        isNotEmpty,
      );
      expect(text.where((t) => t.contains('dashboard content')), isEmpty);
      semantics.dispose();
    });

    testWidgets('a note field loses focus and the keyboard cannot move focus '
        'back into it', (tester) async {
      final focusNode = FocusNode();
      final controller = TextEditingController(text: 'private note');
      addTearDown(focusNode.dispose);
      addTearDown(controller.dispose);
      await pumpGate(
        tester,
        timeout: LockTimeout.immediately,
        home: Scaffold(
          body: TextField(focusNode: focusNode, controller: controller),
        ),
      );
      focusNode.requestFocus();
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);

      await lockNow(tester);
      expect(focusNode.hasFocus, isFalse);

      // A hardware keyboard tabbing around, and code still running
      // underneath asking for focus directly.
      for (var i = 0; i < 5; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(focusNode.hasFocus, isFalse);
      }
      focusNode.requestFocus();
      await tester.pump();
      expect(focusNode.hasFocus, isFalse);
      expect(controller.text, 'private note');
    });

    testWidgets('animations underneath pause while locked and resume after '
        'unlock', (tester) async {
      final tickerEnabled = <bool>[];
      await pumpGate(
        tester,
        timeout: LockTimeout.immediately,
        gate: _FixedResultGate(true),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              tickerEnabled.add(TickerMode.valuesOf(context).enabled);
              return const Text('dashboard content');
            },
          ),
        ),
      );
      expect(tickerEnabled.last, isTrue);

      await lockNow(tester);
      expect(tickerEnabled.last, isFalse);

      _comeBack();
      await tester.pump();
      await tester.tap(find.text('Unlock'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Inner Flare is locked'), findsNothing);
      expect(tickerEnabled.last, isTrue);
    });

    testWidgets('the screen underneath keeps its state through a lock and '
        'unlock (regression guard)', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await pumpGate(
        tester,
        timeout: LockTimeout.immediately,
        gate: _FixedResultGate(true),
        home: Scaffold(body: TextField(controller: controller)),
      );
      await tester.enterText(find.byType(TextField), 'half-written note');
      final stateBefore = tester.state(find.byType(EditableText));

      await lockNow(tester);
      _comeBack();
      await tester.pump();
      await tester.tap(find.text('Unlock'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('half-written note'), findsOneWidget);
      expect(tester.state(find.byType(EditableText)), same(stateBefore));
    });
  });
}
