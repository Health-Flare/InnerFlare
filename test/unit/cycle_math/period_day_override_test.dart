// The user's own "Period day" choice (issue #103, docs/features/log.feature)
// against the pure cycle-math functions. No Flutter, no database.

import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/core/cycle_math/cycle_math.dart';
import 'package:inner_flare/models/period_flow.dart';

DateTime _d(int day) => DateTime.utc(2026, 3, day);

const _s = PeriodFlow.spotting;
const _l = PeriodFlow.light;
const _m = PeriodFlow.medium;
const _h = PeriodFlow.heavy;

List<DateTime> _starts(
  Map<DateTime, PeriodFlow?> flows, [
  Map<DateTime, bool> overrides = const {},
]) {
  return periodStartsFromFlowLog(
    effectivePeriodFlowLog(flowByDate: flows, periodDayOverrides: overrides),
  );
}

void main() {
  group('effectivePeriodFlowLog', () {
    test('with no choices it is the logged flow, minus days without flow', () {
      final log = effectivePeriodFlowLog(
        flowByDate: {_d(1): _m, _d(2): null, _d(3): _s},
        periodDayOverrides: const {},
      );
      expect(log, {_d(1): _m, _d(3): _s});
    });

    test('a day marked as not a period day is dropped', () {
      final log = effectivePeriodFlowLog(
        flowByDate: {_d(1): _h, _d(2): _h},
        periodDayOverrides: {_d(1): false},
      );
      expect(log.keys, [_d(2)]);
    });

    test('spotting marked as a period day counts as real flow', () {
      final log = effectivePeriodFlowLog(
        flowByDate: {_d(1): _s},
        periodDayOverrides: {_d(1): true},
      );
      expect(log[_d(1)], isNot(_s));
      expect(log[_d(1)], isNotNull);
    });

    test('a day with no flow marked as a period day is included', () {
      final log = effectivePeriodFlowLog(
        flowByDate: {_d(1): null},
        periodDayOverrides: {_d(1): true},
      );
      expect(log.keys, [_d(1)]);
      expect(log[_d(1)], isNot(_s));
    });

    test('a choice for a day with nothing logged at all still counts', () {
      final log = effectivePeriodFlowLog(
        flowByDate: const {},
        periodDayOverrides: {_d(1): true},
      );
      expect(log.keys, [_d(1)]);
    });

    test('real flow marked as a period day keeps its logged level', () {
      final log = effectivePeriodFlowLog(
        flowByDate: {_d(1): _h},
        periodDayOverrides: {_d(1): true},
      );
      expect(log[_d(1)], _h);
    });

    test('dates are normalised to UTC midnight', () {
      final log = effectivePeriodFlowLog(
        flowByDate: {DateTime(2026, 3, 1, 15): _m},
        periodDayOverrides: {DateTime(2026, 3, 2, 9): true},
      );
      expect(log.keys.toSet(), {_d(1), _d(2)});
    });
  });

  group('period starts with the user\'s choices', () {
    test('spotting the user marks as a period day starts the period', () {
      expect(_starts({_d(1): _s, _d(2): _m}, {_d(1): true}), [_d(1)]);
    });

    test('spotting alone marked as a period day starts a period', () {
      expect(_starts({_d(15): _s}, {_d(15): true}), [_d(15)]);
    });

    test('a day with no flow marked as a period day starts a period', () {
      expect(_starts({_d(1): null}, {_d(1): true}), [_d(1)]);
    });

    test('bleeding marked as not a period starts nothing', () {
      expect(
        _starts({_d(10): _h, _d(11): _h}, {_d(10): false, _d(11): false}),
        isEmpty,
      );
    });

    test('marking the first day as not a period moves the start', () {
      expect(_starts({_d(1): _m, _d(2): _m, _d(3): _m}, {_d(1): false}), [
        _d(2),
      ]);
    });

    test('a day marked off in the middle counts as a day without flow', () {
      // 1, 2 flow; 3 and 4 marked off; 5 flow: two days without a period
      // day, so 5 starts a new period.
      expect(
        _starts(
          {_d(1): _m, _d(2): _m, _d(3): _l, _d(4): _l, _d(5): _m},
          {_d(3): false, _d(4): false},
        ),
        [_d(1), _d(5)],
      );
    });

    test('no choices gives exactly the #101 rule', () {
      final flows = {_d(1): _s, _d(2): _m, _d(3): _h, _d(20): _s};
      expect(
        _starts(flows),
        periodStartsFromFlowLog({
          for (final e in flows.entries) e.key: e.value,
        }),
      );
    });
  });

  group('periodDaysFromFlowLog', () {
    test('every flow day of a period counts, spotting inside it too', () {
      expect(periodDaysFromFlowLog({_d(1): _m, _d(2): _h, _d(3): _s}), {
        _d(1),
        _d(2),
        _d(3),
      });
    });

    test('spotting before the first real flow day is part of the period', () {
      expect(periodDaysFromFlowLog({_d(1): _s, _d(2): _m}), {_d(1), _d(2)});
    });

    test('spotting alone is not a period day', () {
      expect(periodDaysFromFlowLog({_d(15): _s}), isEmpty);
    });

    test('the unlogged gap day inside a period is not itself a period day', () {
      expect(periodDaysFromFlowLog({_d(1): _m, _d(3): _m}), {_d(1), _d(3)});
    });

    test('separate episodes are judged separately', () {
      expect(periodDaysFromFlowLog({_d(1): _m, _d(2): _l, _d(10): _s}), {
        _d(1),
        _d(2),
      });
    });

    test('no flow, no period days', () {
      expect(periodDaysFromFlowLog(const {}), isEmpty);
    });
  });

  group('periodDayFromFlowAlone', () {
    test('light, medium and heavy are period days', () {
      for (final flow in [_l, _m, _h]) {
        expect(periodDayFromFlowAlone(flow), isTrue, reason: flow.name);
      }
    });

    test('no flow is not a period day', () {
      expect(periodDayFromFlowAlone(null), isFalse);
    });

    test('spotting depends on the days around it', () {
      expect(periodDayFromFlowAlone(_s), isNull);
    });
  });

  group('normalisePeriodDayOverride', () {
    test('no choice stays no choice', () {
      for (final flow in [null, ...PeriodFlow.values]) {
        expect(normalisePeriodDayOverride(flow: flow, choice: null), isNull);
      }
    });

    test('"period day" on real flow says nothing new, so is not stored', () {
      for (final flow in [_l, _m, _h]) {
        expect(normalisePeriodDayOverride(flow: flow, choice: true), isNull);
      }
    });

    test('"not a period day" with no flow says nothing new', () {
      expect(normalisePeriodDayOverride(flow: null, choice: false), isNull);
    });

    test('a choice that disagrees with flow is kept', () {
      expect(normalisePeriodDayOverride(flow: null, choice: true), isTrue);
      expect(normalisePeriodDayOverride(flow: _h, choice: false), isFalse);
    });

    test('either choice on spotting is kept', () {
      expect(normalisePeriodDayOverride(flow: _s, choice: true), isTrue);
      expect(normalisePeriodDayOverride(flow: _s, choice: false), isFalse);
    });
  });

  group('days since the period ended, with choices', () {
    test('spotting marked off after a period is not part of it', () {
      final log = effectivePeriodFlowLog(
        flowByDate: {_d(1): _m, _d(2): _m, _d(3): _s},
        periodDayOverrides: {_d(3): false},
      );
      expect(
        lastLoggedPeriodEndDate(
          lastPeriodStart: _d(1),
          datesWithPeriodFlow: log.keys.toSet(),
        ),
        _d(2),
      );
    });
  });
}
