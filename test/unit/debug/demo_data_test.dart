// Guards the app-store-screenshot demo dataset: it must never log a
// future day (nothing in the app can log ahead of "now") and must
// produce cycle history real enough for the insights screen to show a
// populated average/variability/prediction rather than an empty state.
// See lib/core/debug/demo_data.dart.

import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/core/cycle_math/cycle_math.dart';
import 'package:inner_flare/core/debug/demo_data.dart';

void main() {
  final now = DateTime.utc(2026, 9, 8);

  test('never logs a day after now', () {
    final logs = buildDemoCycleLogs(now: now);
    for (final log in logs) {
      expect(log.date.isAfter(now), isFalse, reason: '${log.date} is future');
    }
  });

  test('never logs the same date twice', () {
    final logs = buildDemoCycleLogs(now: now);
    final dates = logs.map((log) => log.date).toSet();
    expect(dates, hasLength(logs.length));
  });

  test('leaves today and yesterday unlogged', () {
    final logs = buildDemoCycleLogs(now: now);
    final dates = logs.map((log) => log.date).toSet();
    expect(dates.contains(now), isFalse);
    expect(dates.contains(now.subtract(const Duration(days: 1))), isFalse);
  });

  test('produces enough complete cycles for a non-irregular average', () {
    final logs = buildDemoCycleLogs(now: now);
    // Mirrors CycleDayLogRepository._isPeriodStart: a logged day is a
    // period start iff the immediately preceding calendar day has no
    // period flow logged.
    final logsByDate = {for (final log in logs) log.date: log};
    final periodStarts = [
      for (final log in logs)
        if (log.periodFlow != null &&
            logsByDate[log.date.subtract(const Duration(days: 1))]
                    ?.periodFlow ==
                null)
          log.date,
    ];

    final lengths = cycleLengthsFromPeriodStarts(periodStarts);
    expect(lengths.length, greaterThanOrEqualTo(4));
    expect(averageCycleLength(lengths), isNotNull);
    expect(cycleLengthsAreIrregular(lengths), isFalse);
  });
}
