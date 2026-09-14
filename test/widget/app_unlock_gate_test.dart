import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/core/providers/database_provider.dart';
import 'package:inner_flare/core/security/app_unlock_gate.dart';
import 'package:inner_flare/core/theme/app_theme.dart';
import 'package:inner_flare/data/database/schema.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../helpers/test_app_builder.dart';
import '../helpers/test_database.dart';

/// Covers docs/features/unlock.feature's first-open scenarios: a single
/// dedicated unlock screen instead of a flash of partially-loaded content,
/// nothing about the database touched until the user taps "Unlock", a
/// clear in-place explanation and single retry on failure, and the same
/// visual language as the idle re-lock screen (see
/// test/widget/app_lock_gate_test.dart).
void main() {
  setUpAll(useInMemoryTestDatabaseFactory);

  Widget wrapped({String text = 'dashboard content'}) {
    return Scaffold(body: Text(text));
  }

  testWidgets(
    'shows a dedicated unlock screen with an enabled "Unlock" button, '
    'without touching the database at all',
    (tester) async {
      var openAttempts = 0;
      await pumpTestApp(
        tester,
        AppUnlockGate(child: wrapped()),
        overrides: [
          appDatabaseProvider.overrideWith((ref) async {
            openAttempts++;
            return Completer<Database>().future;
          }),
        ],
      );
      await tester.pump();

      expect(find.text('Inner Flare is locked'), findsOneWidget);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);
      expect(find.text('Unlock'), findsOneWidget);

      // Same visual language as the idle re-lock screen
      // (AppLockScreen) — this shouldn't feel like a second, different
      // mechanism.
      final icon = tester.widget<Icon>(find.byIcon(Icons.lock_rounded));
      expect(icon.color, AppColors.softOrange);

      // Sitting on this screen must never touch the database on its own —
      // only a tap should.
      await tester.pump(const Duration(seconds: 5));
      expect(openAttempts, 0);
    },
  );

  testWidgets('gates whatever screen is on top, regardless of what it is — '
      'onboarding on a first-ever launch just as much as the dashboard', (
    tester,
  ) async {
    final db = await openInMemoryTestDatabase(onCreate: onCreate);
    addTearDown(db.close);

    await pumpTestApp(
      tester,
      AppUnlockGate(child: wrapped(text: 'onboarding step 1')),
      overrides: [appDatabaseProvider.overrideWith((ref) async => db)],
    );
    await tester.pump();

    expect(find.text('Inner Flare is locked'), findsOneWidget);
    expect(find.text('onboarding step 1'), findsNothing);

    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();

    expect(find.text('Inner Flare is locked'), findsNothing);
    expect(find.text('onboarding step 1'), findsOneWidget);
  });

  testWidgets(
    'tapping "Unlock" is what starts opening the database — exactly once',
    (tester) async {
      var openAttempts = 0;
      final completer = Completer<Database>();
      await pumpTestApp(
        tester,
        AppUnlockGate(child: wrapped()),
        overrides: [
          appDatabaseProvider.overrideWith((ref) {
            openAttempts++;
            return completer.future;
          }),
        ],
      );
      await tester.pump();
      expect(openAttempts, 0);

      await tester.tap(find.text('Unlock'));
      await tester.pump();

      expect(openAttempts, 1);
      // While the attempt is in flight, the button is disabled and
      // relabelled — same pattern as AppLockScreen — so it can't be
      // tapped again to fire a second, overlapping attempt.
      expect(find.text('Unlocking…'), findsOneWidget);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    },
  );

  testWidgets(
    'successful open dismisses the unlock screen, with the wrapped screen '
    'shown fully loaded rather than flashing a partial state first',
    (tester) async {
      final db = await openInMemoryTestDatabase(onCreate: onCreate);
      addTearDown(db.close);

      await pumpTestApp(
        tester,
        AppUnlockGate(child: wrapped()),
        overrides: [appDatabaseProvider.overrideWith((ref) async => db)],
      );
      await tester.pump();

      await tester.tap(find.text('Unlock'));
      await tester.pumpAndSettle();

      expect(find.text('Inner Flare is locked'), findsNothing);
      expect(find.text('dashboard content'), findsOneWidget);
    },
  );

  testWidgets('a failure explains itself directly on the unlock screen, with a '
      'single "Unlock" retry action', (tester) async {
    await pumpTestApp(
      tester,
      AppUnlockGate(child: wrapped()),
      overrides: [
        appDatabaseProvider.overrideWith((ref) async {
          throw Exception('boom');
        }),
      ],
    );
    await tester.pump();

    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();

    expect(find.text('Inner Flare is locked'), findsOneWidget);
    expect(find.text('Unlock'), findsOneWidget);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNotNull);
  });

  testWidgets('tapping "Unlock" after a failure retries exactly once', (
    tester,
  ) async {
    var openAttempts = 0;
    await pumpTestApp(
      tester,
      AppUnlockGate(child: wrapped()),
      overrides: [
        appDatabaseProvider.overrideWith((ref) async {
          openAttempts++;
          throw Exception('boom');
        }),
      ],
    );
    await tester.pump();

    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();
    expect(openAttempts, 1);

    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();

    expect(
      openAttempts,
      2,
      reason: 'one tap should trigger exactly one retry, not zero or many',
    );
  });

  testWidgets('once open, the session is never re-gated on its own', (
    tester,
  ) async {
    final db = await openInMemoryTestDatabase(onCreate: onCreate);
    addTearDown(db.close);

    await pumpTestApp(
      tester,
      AppUnlockGate(child: wrapped()),
      overrides: [appDatabaseProvider.overrideWith((ref) async => db)],
    );
    await tester.pump();
    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();
    expect(find.text('Inner Flare is locked'), findsNothing);

    // Nothing about the passage of time alone should re-trigger the
    // unlock screen — only an idle re-lock (docs/features/app_lock.feature)
    // does that, and that's a separate, deliberate mechanism.
    await tester.pump(const Duration(seconds: 30));
    expect(find.text('Inner Flare is locked'), findsNothing);
    expect(find.text('dashboard content'), findsOneWidget);
  });
}
