// Exercises docs/features/insights.feature against the pure cycle-math
// module. No Flutter, no database — see lib/core/cycle_math/cycle_math.dart.

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
}
