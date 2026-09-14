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
/// no tap needed for the first attempt, a clear in-place explanation and
/// single retry on failure, and the same visual language as the idle
/// re-lock screen (see test/widget/app_lock_gate_test.dart).
void main() {
  setUpAll(useInMemoryTestDatabaseFactory);

  Widget wrapped({String text = 'dashboard content'}) {
    return Scaffold(body: Text(text));
  }

  testWidgets(
    'shows a dedicated unlock screen — not the wrapped screen — while the '
    'database is still opening, with no tap needed for this first attempt',
    (tester) async {
      final completer = Completer<Database>();
      await pumpTestApp(
        tester,
        AppUnlockGate(child: wrapped()),
        overrides: [
          appDatabaseProvider.overrideWith((ref) => completer.future),
        ],
      );
      await tester.pump();

      expect(find.text('Inner Flare is locked'), findsOneWidget);
      expect(find.text('Unlock'), findsNothing);

      // Same visual language as the idle re-lock screen
      // (AppLockScreen) — this shouldn't feel like a second, different
      // mechanism.
      final icon = tester.widget<Icon>(find.byIcon(Icons.lock_rounded));
      expect(icon.color, AppColors.softOrange);
    },
  );

  testWidgets('gates whatever screen is on top, regardless of what it is — '
      'onboarding on a first-ever launch just as much as the dashboard', (
    tester,
  ) async {
    final completer = Completer<Database>();
    await pumpTestApp(
      tester,
      AppUnlockGate(child: wrapped(text: 'onboarding step 1')),
      overrides: [appDatabaseProvider.overrideWith((ref) => completer.future)],
    );
    await tester.pump();

    expect(find.text('Inner Flare is locked'), findsOneWidget);
    // Covered, not removed — same as AppLockGate — so nothing downstream
    // needs to know it might be locked.
    expect(find.text('onboarding step 1'), findsOneWidget);
  });

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
      await tester.pumpAndSettle();

      expect(find.text('Inner Flare is locked'), findsNothing);
      expect(find.text('dashboard content'), findsOneWidget);
    },
  );

  testWidgets('a failure explains itself directly on the unlock screen, with a '
      'single "Unlock" retry action — not a stray icon or banner elsewhere', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      AppUnlockGate(child: wrapped()),
      overrides: [
        appDatabaseProvider.overrideWith((ref) async {
          throw Exception('boom');
        }),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text('Inner Flare is locked'), findsOneWidget);
    expect(find.text('Unlock'), findsOneWidget);
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
