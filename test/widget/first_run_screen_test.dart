import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/core/privacy/open_privacy_policy.dart';
import 'package:inner_flare/core/providers/security_settings_repository_provider.dart';
import 'package:inner_flare/data/database/schema.dart';
import 'package:inner_flare/data/repositories/security_settings_repository.dart';
import 'package:inner_flare/features/first_run/screens/first_run_screen.dart';
import 'package:inner_flare/features/settings/screens/privacy_disclaimer_screen.dart';
import 'package:inner_flare/features/settings/screens/settings_screen.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../helpers/test_app_builder.dart';
import '../helpers/test_database.dart';

void main() {
  setUpAll(useInMemoryTestDatabaseFactory);

  Database? openDb;

  tearDown(() async {
    await openDb?.close();
    openDb = null;
  });

  Future<List<Override>> overrides({void Function()? onOpenPolicy}) async {
    final db = await openInMemoryTestDatabase(
      onCreate: onCreate,
      version: schemaVersion,
    );
    openDb = db;
    return [
      securitySettingsRepositoryProvider.overrideWith(
        (ref) async => SecuritySettingsRepository(db),
      ),
      if (onOpenPolicy != null)
        privacyPolicyOpenerProvider.overrideWithValue(() async {
          onOpenPolicy();
        }),
    ];
  }

  testWidgets('first launch shows the disclaimer and the privacy link', (
    tester,
  ) async {
    var opened = 0;
    await pumpTestApp(
      tester,
      const FirstRunGate(child: Text('Dashboard')),
      overrides: await overrides(onOpenPolicy: () => opened += 1),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsNothing);
    expect(find.text('Welcome to Inner Flare'), findsOneWidget);
    expect(
      find.textContaining('not a medical or diagnostic device'),
      findsOneWidget,
    );
    expect(find.textContaining('not a diagnosis'), findsOneWidget);
    expect(
      find.textContaining('does not collect, transmit, or share'),
      findsOneWidget,
    );
    expect(find.textContaining('explicitly export'), findsOneWidget);
    expect(find.text('Privacy policy'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Privacy policy'), 100);
    await tester.tap(find.text('Privacy policy'));
    await tester.pump();
    expect(opened, 1);
    expect(find.text('Dashboard'), findsNothing);
  });

  testWidgets('acknowledging dismisses the gate, including on a later '
      'launch', (tester) async {
    final screenOverrides = await overrides();

    await pumpTestApp(
      tester,
      const FirstRunGate(child: Text('Dashboard')),
      overrides: screenOverrides,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Continue'), findsNothing);
    expect(
      await SecuritySettingsRepository(openDb!).getDisclaimerAcknowledged(),
      isTrue,
    );

    await pumpTestApp(
      tester,
      const FirstRunGate(child: Text('Dashboard')),
      overrides: screenOverrides,
    );
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsOneWidget);
    expect(
      find.textContaining('not a medical or diagnostic device'),
      findsNothing,
    );
  });

  testWidgets('Settings About shows the same disclaimer and privacy link', (
    tester,
  ) async {
    var opened = 0;
    await pumpTestApp(
      tester,
      const SettingsScreen(),
      overrides: await overrides(onOpenPolicy: () => opened += 1),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Privacy and disclaimer'), 200);
    await tester.tap(find.text('Privacy and disclaimer'));
    await tester.pumpAndSettle();

    expect(find.byType(PrivacyDisclaimerScreen), findsOneWidget);
    expect(
      find.textContaining('not a medical or diagnostic device'),
      findsOneWidget,
    );
    expect(find.text('Continue'), findsNothing);

    await tester.scrollUntilVisible(find.text('Privacy policy'), 100);
    await tester.tap(find.text('Privacy policy'));
    await tester.pump();
    expect(opened, 1);
  });
}
