// Pure rules for how many cycles a trend chart shows
// (docs/features/dashboard_visualizations.feature, "A trend chart shows
// only as many recent cycles as its card has room for").

import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/core/charts/trend_window.dart';

void main() {
  // Plot-area widths, worked out from the dashboard layout on a 390pt
  // phone: 20pt screen padding each side, 12pt grid gap, 20pt card
  // padding each side, 34pt y-axis column.
  const phoneOneColumn = 95.0;
  const phoneTwoColumn = 276.0;
  const tabletTwoColumn = 650.0;

  group('bar charts', () {
    const policy = TrendWindowPolicy.bar;

    test('never show more than 12 cycles, however wide the card', () {
      expect(policy.capacityFor(tabletTwoColumn), 12);
      expect(policy.capacityFor(5000), 12);
    });

    test('a full-width card on a phone shows 12', () {
      expect(policy.capacityFor(phoneTwoColumn), 12);
    });

    test('a half-width card on a phone shows 5', () {
      expect(policy.capacityFor(phoneOneColumn), 5);
    });

    test('never drops below 2, the minimum for a trend', () {
      expect(policy.capacityFor(10), 2);
      expect(policy.capacityFor(0), 2);
      expect(policy.capacityFor(double.infinity), 2);
    });
  });

  group('line charts', () {
    const policy = TrendWindowPolicy.line;

    test('never show more than 24 cycles, however wide the card', () {
      expect(policy.capacityFor(tabletTwoColumn), 24);
    });

    test('a full-width card on a phone shows 23', () {
      expect(policy.capacityFor(phoneTwoColumn), 23);
    });

    test('a half-width card on a phone shows 7', () {
      expect(policy.capacityFor(phoneOneColumn), 7);
    });
  });

  group('recentWindow', () {
    final lengths = [for (var i = 1; i <= 20; i++) 20 + i];

    test('keeps the most recent values, oldest first', () {
      final window = recentWindow(lengths, 12);
      expect(window.visible, lengths.sublist(8));
      expect(window.total, 20);
      expect(window.isTruncated, isTrue);
    });

    test('leaves a short series alone', () {
      final window = recentWindow([28, 30, 29], 12);
      expect(window.visible, [28, 30, 29]);
      expect(window.total, 3);
      expect(window.isTruncated, isFalse);
    });

    test('does not change the list it was given', () {
      final copy = [...lengths];
      recentWindow(lengths, 5);
      expect(lengths, copy);
    });
  });
}
