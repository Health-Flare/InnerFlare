/// Pure cycle statistics: no Flutter, no database, no `DateTime.now()`.
///
/// Every "now" this module needs is passed in by the caller so results are
/// deterministic and exhaustively unit-testable (see docs/features/insights.feature).
library;

import 'dart:math' as math;

/// Normalizes a date to UTC midnight so day-count math is never skewed by
/// daylight saving time transitions in the local timezone.
DateTime dateOnly(DateTime date) {
  return DateTime.utc(date.year, date.month, date.day);
}

/// Whole days between two dates, DST-safe.
int daysBetween(DateTime from, DateTime to) {
  return dateOnly(to).difference(dateOnly(from)).inDays;
}

/// Cycle lengths (in days) between each consecutive pair of period start
/// dates. [periodStarts] need not be sorted or deduplicated.
///
/// A single period start produces no complete cycle length yet — the app
/// should say "not enough data" rather than fabricate one (see
/// docs/features/insights.feature: "First-ever cycle...").
List<int> cycleLengthsFromPeriodStarts(Iterable<DateTime> periodStarts) {
  final sorted = periodStarts.map(dateOnly).toSet().toList()..sort();
  if (sorted.length < 2) return const [];
  return [
    for (var i = 1; i < sorted.length; i++)
      daysBetween(sorted[i - 1], sorted[i]),
  ];
}

/// Mean of the last [windowSize] cycle lengths, or null if there are none.
double? averageCycleLength(List<int> cycleLengths, {int windowSize = 6}) {
  if (cycleLengths.isEmpty) return null;
  final window = _lastN(cycleLengths, windowSize);
  return window.reduce((a, b) => a + b) / window.length;
}

/// Population standard deviation of the last [windowSize] cycle lengths.
/// Returns null with fewer than 2 cycle lengths — variability is undefined
/// for a single data point.
double? cycleLengthVariability(List<int> cycleLengths, {int windowSize = 6}) {
  final window = _lastN(cycleLengths, windowSize);
  if (window.length < 2) return null;
  final mean = window.reduce((a, b) => a + b) / window.length;
  final variance =
      window.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) /
      window.length;
  return math.sqrt(variance);
}

/// Predicted next period start: [lastPeriodStart] plus the rounded average
/// cycle length. Null if there's no average to draw on yet.
DateTime? predictNextPeriodStart({
  required DateTime lastPeriodStart,
  required double? averageCycleLength,
}) {
  if (averageCycleLength == null) return null;
  return dateOnly(
    lastPeriodStart,
  ).add(Duration(days: averageCycleLength.round()));
}

/// A predicted fertile window, inclusive of both ends.
class FertileWindow {
  const FertileWindow({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  bool includes(DateTime date) {
    final day = dateOnly(date);
    return !day.isBefore(start) && !day.isAfter(end);
  }
}

/// Predicted fertile window computed from the predicted next period start
/// and the user's assumed luteal phase length (BRIEF.md §4.3 settings).
/// Ovulation is estimated as [nextPeriodStart] minus [lutealPhaseLengthDays];
/// the fertile window spans the 5 days before ovulation through ovulation
/// day itself, the standard clinical estimate.
FertileWindow? predictFertileWindow({
  required DateTime? nextPeriodStart,
  required int lutealPhaseLengthDays,
}) {
  if (nextPeriodStart == null) return null;
  final ovulationDay = dateOnly(
    nextPeriodStart,
  ).subtract(Duration(days: lutealPhaseLengthDays));
  return FertileWindow(
    start: ovulationDay.subtract(const Duration(days: 5)),
    end: ovulationDay,
  );
}

/// Standard clinical estimate for luteal phase length, used until the user
/// sets their own value in settings (docs/features/insights.feature covers
/// the settings surface; not yet implemented).
const int defaultLutealPhaseLengthDays = 14;

/// Standard estimate for how many days a period lasts, used until the app
/// computes a per-user average from logged period days (v2 candidate per
/// BRIEF.md §5).
const int defaultPeriodLengthDays = 5;

/// A predicted next-period date range, inclusive of both ends.
class PredictedPeriodRange {
  const PredictedPeriodRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  bool includes(DateTime date) {
    final day = dateOnly(date);
    return !day.isBefore(start) && !day.isAfter(end);
  }
}

/// Predicted next period date range: [nextPeriodStart] through
/// [nextPeriodStart] plus [periodLengthDays] - 1. Null if there's no
/// predicted start yet.
PredictedPeriodRange? predictNextPeriodRange({
  required DateTime? nextPeriodStart,
  required int periodLengthDays,
}) {
  if (nextPeriodStart == null) return null;
  final start = dateOnly(nextPeriodStart);
  return PredictedPeriodRange(
    start: start,
    end: start.add(Duration(days: periodLengthDays - 1)),
  );
}

List<int> _lastN(List<int> values, int n) {
  if (values.length <= n) return values;
  return values.sublist(values.length - n);
}
