// Exercises docs/features/insights.feature and
// docs/features/dashboard_visualizations.feature against the pure
// cycle-math module. No Flutter, no database — see
// lib/core/cycle_math/cycle_math.dart.

import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/core/cycle_math/cycle_math.dart';

void main() {
  group('cycleLengthsFromPeriodStarts', () {
    test('no period starts logged yields no cycle lengths', () {
      expect(cycleLengthsFromPeriodStarts(const []), isEmpty);
    });

    test('a single period start yields no complete cycle length', () {
      expect(cycleLengthsFromPeriodStarts([DateTime.utc(2026, 3, 1)]), isEmpty);
    });

    test('two period starts yield one cycle length', () {
      final lengths = cycleLengthsFromPeriodStarts([
        DateTime.utc(2026, 3, 1),
        DateTime.utc(2026, 3, 29),
      ]);
      expect(lengths, [28]);
    });

    test('unsorted input is sorted before diffing', () {
      final lengths = cycleLengthsFromPeriodStarts([
        DateTime.utc(2026, 3, 29),
        DateTime.utc(2026, 3, 1),
      ]);
      expect(lengths, [28]);
    });

    test('a logging gap is one cycle length, no fabricated days', () {
      // Period start, then nothing logged for 10 days, then a new start.
      final lengths = cycleLengthsFromPeriodStarts([
        DateTime.utc(2026, 1, 1),
        DateTime.utc(2026, 1, 29),
      ]);
      expect(lengths, [28]);
    });
  });

  group('averageCycleLength', () {
    test('no cycle lengths yields no average', () {
      expect(averageCycleLength(const []), isNull);
    });

    test('averages the last N cycle lengths', () {
      expect(averageCycleLength([28, 30, 26], windowSize: 6), 28);
    });

    test('ignores cycle lengths outside the window', () {
      expect(averageCycleLength([100, 28, 30, 26], windowSize: 3), 28);
    });
  });

  group('cycleLengthVariability', () {
    test('a single cycle length has undefined variability', () {
      expect(cycleLengthVariability([28]), isNull);
    });

    test('identical cycle lengths have zero variability', () {
      expect(cycleLengthVariability([28, 28, 28]), 0);
    });

    test('irregular cycles produce non-zero variability', () {
      expect(cycleLengthVariability([21, 35]), greaterThan(0));
    });
  });

  group('predictNextPeriodStart', () {
    test('no average yields no prediction', () {
      expect(
        predictNextPeriodStart(
          lastPeriodStart: DateTime.utc(2026, 8, 24),
          averageCycleLength: null,
        ),
        isNull,
      );
    });

    test('adds the rounded average cycle length to the last start', () {
      final predicted = predictNextPeriodStart(
        lastPeriodStart: DateTime.utc(2026, 8, 24),
        averageCycleLength: 28,
      );
      expect(predicted, DateTime.utc(2026, 9, 21));
    });
  });

  group('predictFertileWindow', () {
    test('no predicted next period yields no fertile window', () {
      expect(
        predictFertileWindow(nextPeriodStart: null, lutealPhaseLengthDays: 14),
        isNull,
      );
    });

    test('spans 5 days before ovulation through ovulation day', () {
      final window = predictFertileWindow(
        nextPeriodStart: DateTime.utc(2026, 9, 21),
        lutealPhaseLengthDays: 14,
      );
      expect(window!.end, DateTime.utc(2026, 9, 7));
      expect(window.start, DateTime.utc(2026, 9, 2));
    });
  });

  group('cycleLengthsAreIrregular', () {
    test('fewer than 2 lengths in the window is never irregular', () {
      expect(cycleLengthsAreIrregular(const []), isFalse);
      expect(cycleLengthsAreIrregular([28]), isFalse);
    });

    test('lengths within 7 days of each other are not irregular', () {
      expect(cycleLengthsAreIrregular([26, 28, 30]), isFalse);
    });

    test('lengths spread by more than 7 days are irregular', () {
      expect(cycleLengthsAreIrregular([21, 35, 27]), isTrue);
    });

    test('only considers the last windowSize lengths', () {
      // Older 21/35 spread would be irregular, but the window only sees
      // the last 2, which are close together.
      expect(
        cycleLengthsAreIrregular([21, 35, 28, 29], windowSize: 2),
        isFalse,
      );
    });
  });

  group('lastLoggedPeriodEndDate', () {
    test('a single logged day is its own end', () {
      final end = lastLoggedPeriodEndDate(
        lastPeriodStart: DateTime.utc(2026, 8, 24),
        datesWithPeriodFlow: {DateTime.utc(2026, 8, 24)},
      );
      expect(end, DateTime.utc(2026, 8, 24));
    });

    test('walks forward through consecutive logged days', () {
      final end = lastLoggedPeriodEndDate(
        lastPeriodStart: DateTime.utc(2026, 8, 24),
        datesWithPeriodFlow: {
          DateTime.utc(2026, 8, 24),
          DateTime.utc(2026, 8, 25),
          DateTime.utc(2026, 8, 26),
        },
      );
      expect(end, DateTime.utc(2026, 8, 26));
    });

    test('stops at the first gap, ignoring unrelated later logged days', () {
      final end = lastLoggedPeriodEndDate(
        lastPeriodStart: DateTime.utc(2026, 8, 24),
        datesWithPeriodFlow: {
          DateTime.utc(2026, 8, 24),
          DateTime.utc(2026, 8, 25),
          // Gap on the 26th, then an unrelated later logged day — should
          // not be swept in as part of this period.
          DateTime.utc(2026, 9, 10),
        },
      );
      expect(end, DateTime.utc(2026, 8, 25));
    });

    test('flow still logged for today keeps extending the end date', () {
      // A period still being logged has no fixed "end" yet — see
      // docs/features/quick_stats.feature, "A period still being logged
      // counts as ongoing, not yet ended".
      final end = lastLoggedPeriodEndDate(
        lastPeriodStart: DateTime.utc(2026, 8, 24),
        datesWithPeriodFlow: {
          DateTime.utc(2026, 8, 24),
          DateTime.utc(2026, 8, 25),
          DateTime.utc(2026, 8, 26),
          DateTime.utc(2026, 8, 27),
        },
      );
      expect(end, DateTime.utc(2026, 8, 27));
    });
  });

  group('daysSinceLastPeriod', () {
    test('defaults to measuring from the end of the last period', () {
      final days = daysSinceLastPeriod(
        lastPeriodStart: DateTime.utc(2026, 8, 24),
        datesWithPeriodFlow: {
          DateTime.utc(2026, 8, 24),
          DateTime.utc(2026, 8, 25),
          DateTime.utc(2026, 8, 26),
        },
        now: DateTime.utc(2026, 9, 3),
      );
      // Last logged flow day is the 26th, 8 days before the 3rd.
      expect(days, 8);
    });

    test('measures from the start when referencePoint is start', () {
      final days = daysSinceLastPeriod(
        lastPeriodStart: DateTime.utc(2026, 8, 24),
        datesWithPeriodFlow: {
          DateTime.utc(2026, 8, 24),
          DateTime.utc(2026, 8, 25),
          DateTime.utc(2026, 8, 26),
        },
        now: DateTime.utc(2026, 9, 3),
        referencePoint: PeriodReferencePoint.start,
      );
      // 10 days between the 24th and the 3rd.
      expect(days, 10);
    });

    test('a period still being logged today reads as 0 days since it '
        'ended, not a stale count', () {
      final days = daysSinceLastPeriod(
        lastPeriodStart: DateTime.utc(2026, 8, 24),
        datesWithPeriodFlow: {
          DateTime.utc(2026, 8, 24),
          DateTime.utc(2026, 8, 25),
          DateTime.utc(2026, 8, 26),
          DateTime.utc(2026, 8, 27),
        },
        now: DateTime.utc(2026, 8, 27),
      );
      expect(days, 0);
    });
  });

  group('estimatedDaysToNextPeriod', () {
    test('no average cycle length yields no estimate', () {
      final estimate = estimatedDaysToNextPeriod(
        lastPeriodStart: DateTime.utc(2026, 8, 24),
        averageCycleLength: null,
        now: DateTime.utc(2026, 9, 3),
      );
      expect(estimate, isNull);
    });

    test('counts down from the predicted next period start', () {
      final estimate = estimatedDaysToNextPeriod(
        lastPeriodStart: DateTime.utc(2026, 8, 24),
        averageCycleLength: 28,
        now: DateTime.utc(2026, 9, 3), // 10 days after the last start
      );
      expect(estimate, 18);
    });

    test('goes negative once the predicted date has passed, rather than '
        'clamping to zero', () {
      final estimate = estimatedDaysToNextPeriod(
        lastPeriodStart: DateTime.utc(2026, 8, 24),
        averageCycleLength: 28,
        now: DateTime.utc(2026, 9, 24), // 31 days after the last start
      );
      expect(estimate, -3);
    });
  });

  group('daysBetween — date/timezone edge cases', () {
    final cases = <(DateTime, DateTime, int)>[
      // Crosses US spring-forward DST transition (2026-03-08).
      (DateTime(2026, 3, 1), DateTime(2026, 3, 29), 28),
      (DateTime(2026, 3, 8), DateTime(2026, 4, 5), 28),
      // Crosses US fall-back DST transition (2026-11-01).
      (DateTime(2026, 11, 1), DateTime(2026, 11, 29), 28),
    ];

    for (final (start, end, expectedDays) in cases) {
      test('$start -> $end is $expectedDays days regardless of DST', () {
        expect(daysBetween(start, end), expectedDays);
      });
    }
  });

  // docs/features/dashboard_visualizations.feature, "Gauge shows a range
  // instead of false precision when data is thin".
  group('hasThinCycleHistory', () {
    test('fewer than 2 complete cycle lengths is thin', () {
      expect(hasThinCycleHistory(const []), isTrue);
      expect(hasThinCycleHistory(const [28]), isTrue);
    });

    test('2+ regular cycle lengths is not thin', () {
      expect(hasThinCycleHistory(const [28, 29, 27]), isFalse);
    });

    test('the last 3 lengths varying by more than 7 days is thin, even '
        'with plenty of history', () {
      expect(hasThinCycleHistory(const [28, 29, 21, 40]), isTrue);
    });

    test('an old irregular stretch outside the window doesn\'t count', () {
      // Last 3 (28, 27, 29) are tight; the 40 four cycles back is out of
      // the default 3-length window.
      expect(hasThinCycleHistory(const [40, 21, 28, 27, 29]), isFalse);
    });
  });

  // docs/features/dashboard_visualizations.feature, "the gauge fills
  // relative to the user's own average cycle length, not a fixed or
  // generic scale".
  group('gaugeFillFraction', () {
    test('null with no average cycle length yet', () {
      expect(
        gaugeFillFraction(elapsedDays: 10, averageCycleLength: null),
        isNull,
      );
    });

    test('fraction of elapsed days over the average cycle length', () {
      expect(
        gaugeFillFraction(elapsedDays: 10, averageCycleLength: 28),
        closeTo(10 / 28, 1e-9),
      );
    });

    test('clamps to 1.0 once the period is overdue, rather than '
        'overflowing the gauge', () {
      expect(gaugeFillFraction(elapsedDays: 40, averageCycleLength: 28), 1.0);
    });

    test('clamps to 0.0 for a negative elapsed-day count', () {
      expect(gaugeFillFraction(elapsedDays: -2, averageCycleLength: 28), 0.0);
    });
  });

  // docs/features/dashboard_visualizations.feature, "The cycle detail
  // table lists every complete cycle and the gap since the one before
  // it".
  group('cycleDetailRows', () {
    test('fewer than 2 period starts yields no rows', () {
      expect(cycleDetailRows(const []), isEmpty);
      expect(cycleDetailRows([DateTime.utc(2026, 1, 1)]), isEmpty);
    });

    test('one complete cycle has no difference to compare against', () {
      final rows = cycleDetailRows([
        DateTime.utc(2026, 1, 1),
        DateTime.utc(2026, 1, 29),
      ]);
      expect(rows, hasLength(1));
      expect(rows.single.start, DateTime.utc(2026, 1, 1));
      expect(rows.single.lengthDays, 28);
      expect(rows.single.differenceFromPreviousDays, isNull);
    });

    test('rows are most-recent-first, unlike the chronological trend '
        'chart', () {
      final rows = cycleDetailRows([
        DateTime.utc(2026, 1, 1), // cycle 1: 28 days
        DateTime.utc(2026, 1, 29), // cycle 2: 30 days
        DateTime.utc(2026, 2, 28), // cycle 3 starts here (still open)
      ]);
      expect(rows.map((r) => r.start), [
        DateTime.utc(2026, 1, 29), // most recent complete cycle first
        DateTime.utc(2026, 1, 1),
      ]);
      expect(rows.map((r) => r.lengthDays), [30, 28]);
    });

    test('each row\'s difference is signed, versus the cycle immediately '
        'before it', () {
      final rows = cycleDetailRows([
        DateTime.utc(2026, 1, 1), // cycle 1: 28 days
        DateTime.utc(2026, 1, 29), // cycle 2: 30 days (+2)
        DateTime.utc(2026, 2, 28), // cycle 3: 25 days (-5)
        DateTime.utc(2026, 3, 25),
      ]);
      expect(rows.map((r) => r.differenceFromPreviousDays), [-5, 2, null]);
    });

    test('unsorted input is sorted before deriving rows', () {
      final rows = cycleDetailRows([
        DateTime.utc(2026, 1, 29),
        DateTime.utc(2026, 1, 1),
      ]);
      expect(rows.single.lengthDays, 28);
    });
  });
}
