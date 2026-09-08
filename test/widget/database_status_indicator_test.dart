import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/core/providers/database_provider.dart';
import 'package:inner_flare/data/database/schema.dart';
import 'package:inner_flare/features/dashboard/widgets/database_status_indicator.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../helpers/test_app_builder.dart';
import '../helpers/test_database.dart';

void main() {
  setUpAll(useInMemoryTestDatabaseFactory);

  Widget wrapped() {
    return Scaffold(appBar: AppBar(actions: const [DatabaseStatusIndicator()]));
  }

  testWidgets(
    'shows a static icon while checking — not an indeterminate spinner, '
    'which would never let pumpAndSettle finish if this state persists',
    (tester) async {
      final completer = Completer<Database>();
      await pumpTestApp(
        tester,
        wrapped(),
        overrides: [
          appDatabaseProvider.overrideWith((ref) => completer.future),
        ],
      );

      expect(find.byIcon(Icons.hourglass_empty_rounded), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Left unresolved deliberately: pumpAndSettle must still be safe to
      // call, since a real device can sit here indefinitely too (e.g. no
      // platform channel wired up).
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.hourglass_empty_rounded), findsOneWidget);
    },
  );

  testWidgets('shows unlocked once the database opens', (tester) async {
    final db = await openInMemoryTestDatabase(onCreate: onCreate);
    addTearDown(db.close);

    await pumpTestApp(
      tester,
      wrapped(),
      overrides: [appDatabaseProvider.overrideWith((ref) async => db)],
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.lock_open_rounded), findsOneWidget);
  });

  testWidgets('shows locked, with a retry action, when opening fails', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      wrapped(),
      overrides: [
        appDatabaseProvider.overrideWith((ref) async {
          throw Exception('boom');
        }),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.lock_rounded), findsOneWidget);

    // Tapping retries by invalidating the provider — with no successful
    // override behind it here, it just fails the same way again, but
    // shouldn't crash or leave the icon stuck mid-transition.
    await tester.tap(find.byIcon(Icons.lock_rounded));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
  });
}
