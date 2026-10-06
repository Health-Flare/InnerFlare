import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/core/providers/backup_exporter_provider.dart';
import 'package:inner_flare/data/export/backup_exporter.dart';
import 'package:inner_flare/features/export/screens/export_screen.dart';

import '../helpers/test_app_builder.dart';

/// Fails the way an unexpected error would, with a path in its message.
class _FailingExporter implements BackupExporter {
  @override
  Future<String> buildFileContents({String? passphrase}) async =>
      throw StateError('disk full at /private/var/tmp/x');
}

void main() {
  Finder encryptSwitch() =>
      find.widgetWithText(SwitchListTile, 'Encrypt export');

  testWidgets('"Encrypt export" is on by default, with the passphrase fields '
      'shown', (tester) async {
    await pumpTestApp(tester, const ExportScreen());

    expect(tester.widget<SwitchListTile>(encryptSwitch()).value, isTrue);
    expect(find.widgetWithText(TextField, 'Passphrase'), findsOneWidget);
    expect(
      find.widgetWithText(TextField, 'Confirm passphrase'),
      findsOneWidget,
    );
    expect(find.textContaining('Off by default'), findsNothing);
    expect(find.byKey(const Key('export_plaintext_warning')), findsNothing);
  });

  testWidgets('turning encryption off hides the passphrase fields and warns '
      'what anyone with the file can read', (tester) async {
    await pumpTestApp(tester, const ExportScreen());

    await tester.tap(encryptSwitch());
    await tester.pump();

    expect(find.widgetWithText(TextField, 'Passphrase'), findsNothing);
    expect(
      find.text(
        'Without encryption, anyone who gets this file can read everything '
        'in it: your periods, symptoms, notes, ovulation tests and '
        'temperatures.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'exporting with the default settings and no passphrase is rejected '
    'before anything runs',
    (tester) async {
      await pumpTestApp(tester, const ExportScreen());

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

  testWidgets('an unexpected export failure shows a plain message, not the '
      'raw error', (tester) async {
    await pumpTestApp(
      tester,
      const ExportScreen(),
      overrides: [
        backupExporterProvider.overrideWith((ref) async => _FailingExporter()),
      ],
    );

    await tester.enterText(
      find.widgetWithText(TextField, 'Passphrase'),
      'same-passphrase',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Confirm passphrase'),
      'same-passphrase',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Export'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining("Couldn't create the backup. Nothing was changed."),
      findsOneWidget,
    );
    expect(find.textContaining("Couldn't export:"), findsNothing);
  });
}
