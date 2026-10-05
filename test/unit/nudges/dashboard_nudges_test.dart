// Exercises docs/features/dashboard_nudges.feature ("Only one nudge shows
// at a time", "Duplicate cards trigger the cleanup nudge on their own",
// snooze kinds) and docs/features/dashboard_visualizations.feature (when a
// card is suggested, "No suggestion for a card the user already has", the
// 7-card cleanup threshold) against the pure selection logic. No Flutter,
// no database.

import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/core/nudges/dashboard_nudges.dart';
import 'package:inner_flare/core/nudges/nudge_rules.dart';
import 'package:inner_flare/models/dashboard_card.dart';

final _now = DateTime(2026, 10, 4, 9);

DashboardCardInstance _card(
  String id,
  DashboardCardKind kind, {
  bool visible = true,
  Map<String, String> config = const {},
}) => DashboardCardInstance(
  id: id,
  kind: kind,
  visible: visible,
  order: 0,
  config: config,
);

/// The fresh-install layout: two quick stats, Calendar, Insights.
List<DashboardCardInstance> _defaults() => [
  _card('quick-stat-0', DashboardCardKind.quickStat),
  _card('quick-stat-1', DashboardCardKind.quickStat),
  _card('calendar', DashboardCardKind.calendar),
  _card('insights', DashboardCardKind.insights),
];

DashboardCardInstance _gauge(String id, {bool visible = true}) => _card(
  id,
  DashboardCardKind.gauge,
  visible: visible,
  config: {
    DashboardCardConfigKeys.gaugeMode: GaugeCardMode.daysSinceLastPeriod.name,
  },
);

DashboardCardInstance _trend(
  String id, {
  TrendCardMetric metric = TrendCardMetric.previousCycleLengths,
}) => _card(
  id,
  DashboardCardKind.trend,
  config: {DashboardCardConfigKeys.trendMetric: metric.name},
);

DashboardNudgeInputs _inputs({
  List<DashboardCardInstance>? cards,
  int periodStarts = 0,
}) => DashboardNudgeInputs(
  cards: cards ?? _defaults(),
  periodStartCount: periodStarts,
);

void main() {
  group('applicableNudges: card suggestions', () {
    test('nothing applies on a fresh install with no history', () {
      expect(applicableNudges(_inputs()), isEmpty);
    });

    test('one logged period is enough to suggest a gauge card', () {
      expect(applicableNudges(_inputs(periodStarts: 1)), [
        DashboardNudge.suggestGauge,
      ]);
    });

    test('a trend card needs 2 complete cycles (3 period starts)', () {
      expect(
        applicableNudges(_inputs(periodStarts: 2)),
        isNot(contains(DashboardNudge.suggestTrend)),
      );
      expect(
        applicableNudges(_inputs(periodStarts: 3)),
        contains(DashboardNudge.suggestTrend),
      );
    });

    test('no gauge suggestion once the user has a gauge card, even a '
        'hidden one', () {
      final cards = [..._defaults(), _gauge('g1', visible: false)];
      expect(
        applicableNudges(_inputs(cards: cards, periodStarts: 5)),
        isNot(contains(DashboardNudge.suggestGauge)),
      );
    });

    test('no trend suggestion once the user has a cycle-lengths trend '
        'card', () {
      final cards = [..._defaults(), _trend('t1')];
      expect(
        applicableNudges(_inputs(cards: cards, periodStarts: 5)),
        isNot(contains(DashboardNudge.suggestTrend)),
      );
    });

    test('a trend card for another metric does not count as having one', () {
      final cards = [
        ..._defaults(),
        _trend('t1', metric: TrendCardMetric.flowIntensity),
      ];
      expect(
        applicableNudges(_inputs(cards: cards, periodStarts: 5)),
        contains(DashboardNudge.suggestTrend),
      );
    });
  });

  group('applicableNudges: cleanup', () {
    test('the cleanup threshold is 7, so accepting both suggestions on '
        'the default layout does not trigger it', () {
      expect(cleanupNudgeVisibleCardThreshold, 7);
      final six = [..._defaults(), _gauge('g1'), _trend('t1')];
      expect(
        applicableNudges(_inputs(cards: six)),
        isNot(contains(DashboardNudge.cleanup)),
      );
    });

    test('7 visible cards trigger it', () {
      final seven = [
        ..._defaults(),
        _gauge('g1'),
        _trend('t1'),
        _trend('t2', metric: TrendCardMetric.flowIntensity),
      ];
      expect(applicableNudges(_inputs(cards: seven)), [DashboardNudge.cleanup]);
    });

    test('hidden cards do not count toward the threshold', () {
      final cards = [
        ..._defaults(),
        _gauge('g1'),
        _trend('t1'),
        _card('extra', DashboardCardKind.gauge, visible: false),
      ];
      expect(
        applicableNudges(_inputs(cards: cards)),
        isNot(contains(DashboardNudge.cleanup)),
      );
    });

    test('duplicate cards trigger it below the threshold', () {
      final cards = [..._defaults(), _gauge('g1'), _gauge('g2')];
      expect(
        applicableNudges(_inputs(cards: cards)),
        contains(DashboardNudge.cleanup),
      );
    });
  });

  group('nudgeToShow: one at a time, by priority', () {
    final everything = _inputs(
      cards: [..._defaults(), _gauge('g1'), _gauge('g2')],
      periodStarts: 5,
    );

    test('cleanup wins over suggestions', () {
      expect(
        nudgeToShow(inputs: everything, states: const {}, now: _now),
        DashboardNudge.cleanup,
      );
    });

    test('gauge is suggested before trend', () {
      expect(
        nudgeToShow(
          inputs: _inputs(periodStarts: 5),
          states: const {},
          now: _now,
        ),
        DashboardNudge.suggestGauge,
      );
    });

    test('a dismissed nudge steps aside for the next one', () {
      final states = {
        DashboardNudge.suggestGauge: const NudgeState(
          disposition: NudgeDisposition.dismissedPermanently,
        ),
      };
      expect(
        nudgeToShow(
          inputs: _inputs(periodStarts: 5),
          states: states,
          now: _now,
        ),
        DashboardNudge.suggestTrend,
      );
    });

    test('a nudge snoozed until a card is added stays hidden', () {
      final states = {
        DashboardNudge.cleanup: const NudgeState(
          disposition: NudgeDisposition.snoozedUntilCardAdded,
        ),
      };
      expect(
        nudgeToShow(inputs: everything, states: states, now: _now),
        isNot(DashboardNudge.cleanup),
      );
    });

    test('nothing to show when every applicable nudge is dismissed', () {
      final states = {
        for (final n in DashboardNudge.values)
          n: const NudgeState(
            disposition: NudgeDisposition.dismissedPermanently,
          ),
      };
      expect(
        nudgeToShow(inputs: everything, states: states, now: _now),
        isNull,
      );
    });
  });

  group('snoozeStateFor', () {
    test('cleanup snoozes until the next card is added', () {
      final state = snoozeStateFor(
        DashboardNudge.cleanup,
        now: _now,
        averageCycleLength: 30,
      );
      expect(state.disposition, NudgeDisposition.snoozedUntilCardAdded);
      expect(state.snoozedUntil, isNull);
    });

    test('suggestions snooze for twice the user\'s own average cycle', () {
      final state = snoozeStateFor(
        DashboardNudge.suggestGauge,
        now: _now,
        averageCycleLength: 30,
      );
      expect(state.disposition, NudgeDisposition.snoozed);
      expect(state.snoozedUntil, DateTime.utc(2026, 12, 3));
    });

    test('suggestions fall back to twice 28 days with no history', () {
      final state = snoozeStateFor(
        DashboardNudge.suggestTrend,
        now: _now,
        averageCycleLength: null,
      );
      expect(state.snoozedUntil, DateTime.utc(2026, 11, 29));
    });
  });

  group('extraDuplicateCardIds', () {
    test('keeps the first card of each duplicate group, removes the rest', () {
      final cards = [
        ..._defaults(),
        _gauge('g1'),
        _trend('t1'),
        _gauge('g2'),
        _gauge('g3'),
      ];
      expect(extraDuplicateCardIds(cards), ['g2', 'g3']);
    });

    test('ignores hidden cards', () {
      final cards = [
        ..._defaults(),
        _gauge('g1'),
        _gauge('g2', visible: false),
      ];
      expect(extraDuplicateCardIds(cards), isEmpty);
    });
  });

  group('storage keys', () {
    test('are stable strings, so stored choices survive a rename in code', () {
      expect(DashboardNudge.cleanup.storageKey, 'dashboard_cleanup');
      expect(DashboardNudge.suggestGauge.storageKey, 'suggest_gauge_card');
      expect(DashboardNudge.suggestTrend.storageKey, 'suggest_trend_card');
      expect(
        DashboardNudge.values.map((n) => n.storageKey).toSet().length,
        DashboardNudge.values.length,
      );
    });
  });
}
