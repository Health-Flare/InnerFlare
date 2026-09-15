import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/features/export/screens/import_screen.dart';

import '../helpers/test_app_builder.dart';

void main() {
  testWidgets('renders the choose-file entry point', (tester) async {
    await pumpTestApp(tester, const ImportScreen());

    expect(find.text('Choose backup file…'), findsOneWidget);
  });
}
