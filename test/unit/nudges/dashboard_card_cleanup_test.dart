// Exercises docs/features/dashboard_visualizations.feature's cleanup-
// nudge scenarios against the pure trigger logic. No Flutter, no
// database — see lib/core/nudges/dashboard_card_cleanup.dart.

import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/core/nudges/dashboard_card_cleanup.dart';
import 'package:inner_flare/models/dashboard_card.dart';

void main() {
  DashboardCardInstance calendar(int order) => DashboardCardInstance(
    id: 'calendar',
    kind: DashboardCardKind.calendar,
    visible: true,
    order: order,
  );

  group('hasEnoughCardsForCleanupNudge', () {
    test('fewer than 6 cards does not trigger the nudge', () {
      final cards = List.generate(5, calendar);
      expect(hasEnoughCardsForCleanupNudge(cards), isFalse);
    });

    test('exactly 6 cards triggers the nudge', () {
      final cards = List.generate(6, calendar);
      expect(hasEnoughCardsForCleanupNudge(cards), isTrue);
    });

    test('more than 6 cards still triggers the nudge', () {
      final cards = List.generate(9, calendar);
      expect(hasEnoughCardsForCleanupNudge(cards), isTrue);
    });

    test('a custom threshold is honored', () {
      final cards = List.generate(3, calendar);
      expect(hasEnoughCardsForCleanupNudge(cards, threshold: 3), isTrue);
      expect(hasEnoughCardsForCleanupNudge(cards, threshold: 4), isFalse);
    });
  });

  group('findDuplicateCardGroups', () {
    test('no duplicates among distinct cards', () {
      final cards = [
        calendar(0),
        newGaugeCardInstance(order: 1, mode: GaugeCardMode.daysSinceLastPeriod),
        newGaugeCardInstance(
          order: 2,
          mode: GaugeCardMode.estimatedDaysUntilNextPeriod,
        ),
      ];
      expect(findDuplicateCardGroups(cards), isEmpty);
    });

    test('two gauge cards with the same mode are duplicates', () {
      final first = newGaugeCardInstance(
        order: 0,
        mode: GaugeCardMode.daysSinceLastPeriod,
      );
      final second = newGaugeCardInstance(
        order: 1,
        mode: GaugeCardMode.daysSinceLastPeriod,
      );
      final groups = findDuplicateCardGroups([first, second]);
      expect(groups, hasLength(1));
      expect(groups.single, unorderedEquals([first, second]));
    });

    test('two trend cards with the same metric are duplicates, even with '
        'different chart types', () {
      final bar = newTrendCardInstance(
        order: 0,
        metric: TrendCardMetric.previousCycleLengths,
        chartType: TrendChartType.bar,
      );
      final line = newTrendCardInstance(
        order: 1,
        metric: TrendCardMetric.previousCycleLengths,
        chartType: TrendChartType.line,
      );
      expect(findDuplicateCardGroups([bar, line]), hasLength(1));
    });

    test('trend cards with different metrics are not duplicates', () {
      final lengths = newTrendCardInstance(
        order: 0,
        metric: TrendCardMetric.previousCycleLengths,
      );
      final variability = newTrendCardInstance(
        order: 1,
        metric: TrendCardMetric.cycleLengthVariability,
      );
      expect(findDuplicateCardGroups([lengths, variability]), isEmpty);
    });

    test('calendar and insights are never flagged as duplicates', () {
      final cards = [calendar(0), calendar(1)];
      expect(findDuplicateCardGroups(cards), isEmpty);
    });

    test('three of the same gauge mode form a single group of three', () {
      final cards = List.generate(3, (i) => newGaugeCardInstance(order: i));
      final groups = findDuplicateCardGroups(cards);
      expect(groups, hasLength(1));
      expect(groups.single, hasLength(3));
    });
  });
}
