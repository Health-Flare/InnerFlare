import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/main.dart';

void main() {
  testWidgets('app boots through the loading screen to the dashboard', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const InnerFlareApp());
    await tester.pump(); // flush the loading screen's readyFuture
    await tester.pump(const Duration(milliseconds: 1400)); // min display time
    await tester.pump(const Duration(milliseconds: 500)); // page transition

    expect(find.text('InnerFlare'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
  });
}
