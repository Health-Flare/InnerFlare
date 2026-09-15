import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/features/export/screens/export_screen.dart';

import '../helpers/test_app_builder.dart';

void main() {
  testWidgets('the passphrase fields are hidden until "Encrypt export" is on', (
    tester,
  ) async {
    await pumpTestApp(tester, const ExportScreen());

    expect(find.widgetWithText(TextField, 'Passphrase'), findsNothing);

    await tester.tap(find.widgetWithText(SwitchListTile, 'Encrypt export'));
    await tester.pump();

    expect(find.widgetWithText(TextField, 'Passphrase'), findsOneWidget);
    expect(
      find.widgetWithText(TextField, 'Confirm passphrase'),
      findsOneWidget,
    );
  });

  testWidgets(
    'exporting encrypted with an empty passphrase is rejected before anything runs',
    (tester) async {
      await pumpTestApp(tester, const ExportScreen());

      await tester.tap(find.widgetWithText(SwitchListTile, 'Encrypt export'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Export'));
      await tester.pump();

      expect(
        find.text('Enter a passphrase, or turn off "Encrypt export".'),
        findsOneWidget,
      );
    },
  );

  testWidgets('mismatched passphrases are rejected before anything runs', (
    tester,
  ) async {
    await pumpTestApp(tester, const ExportScreen());

    await tester.tap(find.widgetWithText(SwitchListTile, 'Encrypt export'));
    await tester.pump();
    await tester.enterText(
      find.widgetWithText(TextField, 'Passphrase'),
      'first-passphrase',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Confirm passphrase'),
      'different-passphrase',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Export'));
    await tester.pump();

    expect(find.text("Passphrases don't match."), findsOneWidget);
  });
}
