// docs/features/dashboard_visualizations.feature, "A trend chart shows
// only as many recent cycles as its card has room for". The capacity
// rules themselves are covered in test/unit/charts/trend_window_test.dart;
// this checks the card wires them to its real width and says what it hid.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/core/providers/dashboard_visualization_displays_provider.dart';
import 'package:inner_flare/features/dashboard/widgets/trend_card.dart';
import 'package:inner_flare/models/dashboard_card.dart';

void main() {
  // Card widths on a 390pt phone: full width is the screen less 20pt
  // padding each side; half width also loses half the 12pt grid gap.
  const phoneTwoColumn = 350.0;
  const phoneOneColumn = 169.0;

  final twentyCycles = [for (var i = 0; i < 20; i++) 26 + (i % 5)];

  Future<TrendChartPainter> pumpCard(
    WidgetTester tester, {
    required double width,
    required List<int> lengths,
    TrendChartType chartType = TrendChartType.bar,
  }) async {
    final instance = newTrendCardInstance(order: 0, chartType: chartType);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          trendCardDisplayProvider(instance).overrideWith(
            (ref) async => TrendCardDisplay(
              metric: TrendCardMetric.previousCycleLengths,
              chartType: chartType,
              cycleLengths: lengths,
              averageCycleLength: 28,
              hasEnoughHistory: lengths.length >= 2,
            ),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: width,
                child: TrendCard(instance: instance),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final paint = tester.widget<CustomPaint>(
      find.byKey(const ValueKey('trend_chart_plot')),
    );
    return paint.painter! as TrendChartPainter;
  }

  testWidgets('a full-width bar chart shows the last 12 of 20 cycles', (
    tester,
  ) async {
    final painter = await pumpCard(
      tester,
      width: phoneTwoColumn,
      lengths: twentyCycles,
    );
    expect(painter.values, twentyCycles.sublist(8));
    expect(find.text('Last 12 of 20 cycles'), findsOneWidget);
  });

  testWidgets('a half-width bar chart shows the last 5', (tester) async {
    final painter = await pumpCard(
      tester,
      width: phoneOneColumn,
      lengths: twentyCycles,
    );
    expect(painter.values, twentyCycles.sublist(15));
    expect(find.text('Last 5 of 20 cycles'), findsOneWidget);
  });

  testWidgets('a line chart in the same card shows more cycles', (
    tester,
  ) async {
    final painter = await pumpCard(
      tester,
      width: phoneTwoColumn,
      lengths: twentyCycles,
      chartType: TrendChartType.line,
    );
    expect(painter.values, twentyCycles);
    expect(find.text('Last 20 of 20 cycles'), findsNothing);
  });

  testWidgets('a short history is drawn whole, with no caption', (
    tester,
  ) async {
    final painter = await pumpCard(
      tester,
      width: phoneTwoColumn,
      lengths: [28, 31, 27],
    );
    expect(painter.values, [28, 31, 27]);
    expect(find.textContaining(' cycles'), findsNothing);
  });

  testWidgets('the y axis scales to the cycles on screen, not hidden ones', (
    tester,
  ) async {
    // A 60-day cycle long ago would squash every recent bar if the
    // scale still counted it.
    final lengths = [60, ...List.filled(12, 28)];
    final painter = await pumpCard(
      tester,
      width: phoneTwoColumn,
      lengths: lengths,
    );
    expect(painter.values, List.filled(12, 28));
    expect(find.text('${(28 * 1.15).round()}d'), findsOneWidget);
  });
}
