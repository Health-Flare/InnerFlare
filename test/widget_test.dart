import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/main.dart';

void main() {
  testWidgets('app boots to the dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const InnerFlareApp());

    expect(find.text('InnerFlare'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
  });
}
