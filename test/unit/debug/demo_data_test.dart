// Guards the app-store-screenshot demo dataset: it must never log a
// future day (nothing in the app can log ahead of "now") and must
// produce cycle history real enough for the insights screen to show a
// populated average/variability/prediction rather than an empty state.
// See lib/core/debug/demo_data.dart.

import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/core/cycle_math/cycle_math.dart';
import 'package:inner_flare/core/debug/demo_data.dart';
import 'package:inner_flare/models/cycle_day_log.dart';
import 'package:inner_flare/models/period_flow.dart';

/// The same rule the repository uses (issue #101).
List<DateTime> _periodStartsOf(List<CycleDayLog> logs) {
  return periodStartsFromFlowLog(<DateTime, PeriodFlow>{
    for (final log in logs)
      if (log.periodFlow != null) log.date: log.periodFlow!,
  });
}

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
    final lengths = cycleLengthsFromPeriodStarts(_periodStartsOf(logs));
    expect(lengths, [28, 27, 29, 28, 30]);
    expect(averageCycleLength(lengths), isNotNull);
    expect(cycleLengthsAreIrregular(lengths), isFalse);
  });

  group('perimenopause dataset', () {
    test('never logs a day after now', () {
      for (final log in buildPerimenopauseDemoCycleLogs(now: now)) {
        expect(log.date.isAfter(now), isFalse, reason: '${log.date} is future');
      }
    });

    test('never logs the same date twice', () {
      final logs = buildPerimenopauseDemoCycleLogs(now: now);
      expect(logs.map((log) => log.date).toSet(), hasLength(logs.length));
    });

    test('leaves today and yesterday unlogged', () {
      final dates = buildPerimenopauseDemoCycleLogs(
        now: now,
      ).map((log) => log.date).toSet();
      expect(dates.contains(now), isFalse);
      expect(dates.contains(now.subtract(const Duration(days: 1))), isFalse);
    });

    test('produces the intended irregular cycle lengths', () {
      final logs = buildPerimenopauseDemoCycleLogs(now: now);
      final lengths = cycleLengthsFromPeriodStarts(_periodStartsOf(logs));
      // Two of the generated periods open with a day of spotting. Since
      // #101 cycle day 1 is the first day of real flow, so those periods
      // start a day later than the generator's own start dates: the 27
      // and 35 day gaps read as 28 and 34.
      expect(lengths, [26, 24, 31, 28, 45, 34, 58]);
      expect(cycleLengthsAreIrregular(lengths), isTrue);
    });

    test('is deterministic for a given now', () {
      expect(
        buildPerimenopauseDemoCycleLogs(now: now),
        buildPerimenopauseDemoCycleLogs(now: now),
      );
    });
  });
}
