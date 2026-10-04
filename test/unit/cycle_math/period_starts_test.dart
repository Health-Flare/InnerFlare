// Exercises the period-start rule in docs/features/log.feature (issue
// #101) against the pure cycle-math function. No Flutter, no database.

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/core/cycle_math/cycle_math.dart';
import 'package:inner_flare/models/period_flow.dart';

DateTime _d(int month, int day) => DateTime.utc(2026, month, day);

/// Builds a flow log from consecutive days starting at [first]; a null
/// entry is a day with nothing logged.
Map<DateTime, PeriodFlow> _run(DateTime first, List<PeriodFlow?> flows) {
  return {
    for (var i = 0; i < flows.length; i++)
      if (flows[i] != null) first.add(Duration(days: i)): flows[i]!,
  };
}

const _s = PeriodFlow.spotting;
const _l = PeriodFlow.light;
const _m = PeriodFlow.medium;
const _h = PeriodFlow.heavy;

void main() {
  group('periodStartsFromFlowLog', () {
    test('no flow logged yields no starts', () {
      expect(periodStartsFromFlowLog(const {}), isEmpty);
    });

    test('a single day of real flow is a start', () {
      expect(periodStartsFromFlowLog({_d(3, 1): _m}), [_d(3, 1)]);
    });

    test('consecutive flow days are one period', () {
      expect(periodStartsFromFlowLog(_run(_d(3, 1), [_m, _h, _h, _l])), [
        _d(3, 1),
      ]);
    });

    test('light, medium and heavy each start a period', () {
      for (final flow in [_l, _m, _h]) {
        expect(periodStartsFromFlowLog({_d(3, 1): flow}), [
          _d(3, 1),
        ], reason: flow.name);
      }
    });

    test('spotting alone never starts a period', () {
      expect(periodStartsFromFlowLog({_d(3, 15): _s}), isEmpty);
      expect(periodStartsFromFlowLog(_run(_d(3, 15), [_s, _s, _s])), isEmpty);
    });

    test('mid-cycle spotting does not split a cycle', () {
      final log = {
        ..._run(_d(3, 1), [_m, _h, _l]),
        _d(3, 15): _s,
        ..._run(_d(3, 29), [_m, _h]),
      };
      expect(periodStartsFromFlowLog(log), [_d(3, 1), _d(3, 29)]);
    });

    test('spotting before a period: day 1 is the first day of real flow', () {
      expect(periodStartsFromFlowLog(_run(_d(3, 1), [_s, _s, _m, _h])), [
        _d(3, 3),
      ]);
    });

    test('spotting at the end of a period does not start a new one', () {
      expect(periodStartsFromFlowLog(_run(_d(3, 1), [_m, _l, _s, _s])), [
        _d(3, 1),
      ]);
    });

    test('one unlogged day inside a period does not split it', () {
      expect(periodStartsFromFlowLog(_run(_d(3, 1), [_m, _m, null, _l])), [
        _d(3, 1),
      ]);
    });

    test('a one-day gap between spotting and real flow is one period', () {
      expect(periodStartsFromFlowLog(_run(_d(3, 1), [_s, null, _m, _h])), [
        _d(3, 3),
      ]);
    });

    test('two days without flow end a period', () {
      expect(periodStartsFromFlowLog(_run(_d(3, 1), [_m, null, null, _m])), [
        _d(3, 1),
        _d(3, 4),
      ]);
    });

    test('a gap of exactly two days after spotting starts fresh', () {
      expect(
        periodStartsFromFlowLog(_run(_d(3, 1), [_m, _s, null, null, _h])),
        [_d(3, 1), _d(3, 5)],
      );
    });

    test('dates with a time of day are normalised to the calendar day', () {
      final log = {
        DateTime.utc(2026, 3, 1, 23, 30): _m,
        DateTime.utc(2026, 3, 2, 0, 15): _m,
      };
      expect(periodStartsFromFlowLog(log), [_d(3, 1)]);
    });

    test('a period crossing the March DST change stays one period', () {
      expect(periodStartsFromFlowLog(_run(_d(3, 7), [_m, _h, null, _l])), [
        _d(3, 7),
      ]);
    });

    test('a period crossing a month and year boundary stays one period', () {
      final log = _run(DateTime.utc(2026, 12, 30), [_m, _h, null, _l]);
      expect(periodStartsFromFlowLog(log), [DateTime.utc(2026, 12, 30)]);
    });

    test('realistic history gives the expected cycle lengths', () {
      final log = {
        ..._run(_d(1, 1), [_s, _m, _h, _h, _l, _s]),
        _d(1, 15): _s,
        ..._run(_d(1, 30), [_m, _h, null, _l]),
        ..._run(_d(2, 27), [_h, _h, _m, _l, _s, null, _s]),
      };
      final starts = periodStartsFromFlowLog(log);
      expect(starts, [_d(1, 2), _d(1, 30), _d(2, 27)]);
      expect(cycleLengthsFromPeriodStarts(starts), [28, 28]);
    });

    test('property: shuffled insertion order gives identical starts', () {
      final random = math.Random(101);
      const flows = [null, null, null, _s, _l, _m, _h];
      for (var round = 0; round < 200; round++) {
        final days = <DateTime, PeriodFlow>{};
        for (var i = 0; i < 90; i++) {
          final flow = flows[random.nextInt(flows.length)];
          if (flow != null) days[_d(1, 1).add(Duration(days: i))] = flow;
        }
        final expected = periodStartsFromFlowLog(days);
        final entries = days.entries.toList()..shuffle(random);
        final shuffled = Map<DateTime, PeriodFlow>.fromEntries(entries);
        expect(periodStartsFromFlowLog(shuffled), expected);
        if (days.values.any((f) => f != _s)) {
          expect(expected, isNotEmpty, reason: 'round $round');
        }
      }
    });

    test('property: every start is real flow with no flow on the 2 days '
        'before it, unless only spotting bridges the gap', () {
      final random = math.Random(7);
      const flows = [null, null, _s, _l, _m, _h];
      for (var round = 0; round < 200; round++) {
        final days = <DateTime, PeriodFlow>{};
        for (var i = 0; i < 60; i++) {
          final flow = flows[random.nextInt(flows.length)];
          if (flow != null) days[_d(1, 1).add(Duration(days: i))] = flow;
        }
        for (final start in periodStartsFromFlowLog(days)) {
          expect(days[start], isNot(_s));
          expect(days[start], isNotNull);
          final dayBefore = days[start.subtract(const Duration(days: 1))];
          final twoBefore = days[start.subtract(const Duration(days: 2))];
          // Anything immediately before a start can only be spotting.
          expect(dayBefore == null || dayBefore == _s, isTrue);
          expect(twoBefore == null || twoBefore == _s, isTrue);
        }
      }
    });
  });

  group('lastLoggedPeriodEndDate with a one-day gap', () {
    test('one unlogged day inside a period does not end it early', () {
      final end = lastLoggedPeriodEndDate(
        lastPeriodStart: _d(3, 1),
        datesWithPeriodFlow: {_d(3, 1), _d(3, 2), _d(3, 4), _d(3, 5)},
      );
      expect(end, _d(3, 5));
    });

    test('two unlogged days end the period', () {
      final end = lastLoggedPeriodEndDate(
        lastPeriodStart: _d(3, 1),
        datesWithPeriodFlow: {_d(3, 1), _d(3, 2), _d(3, 5)},
      );
      expect(end, _d(3, 2));
    });
  });
}
