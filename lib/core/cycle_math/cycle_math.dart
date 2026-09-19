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

/// Whether the last [windowSize] cycle lengths vary by more than [thresholdDays]
/// from each other (max - min), per docs/features/insights.feature,
/// "Irregular cycles still produce an average, clearly caveated". Fewer than
/// 2 cycle lengths in the window can't be irregular — there's nothing to vary
/// against.
bool cycleLengthsAreIrregular(
  List<int> cycleLengths, {
  int windowSize = 3,
  int thresholdDays = 7,
}) {
  final window = _lastN(cycleLengths, windowSize);
  if (window.length < 2) return false;
  final spread = window.reduce(math.max) - window.reduce(math.min);
  return spread > thresholdDays;
}

/// Which point in a period `daysSinceLastPeriod` measures from — see
/// docs/features/quick_stats.feature.
enum PeriodReferencePoint { start, end }

/// The last consecutive day of period flow, walking forward day-by-day
/// from [lastPeriodStart] through [datesWithPeriodFlow]. Stops at the
/// first day without flow, so an unrelated later logged day (e.g. the
/// start of a *different* period) is never swept in.
///
/// A period still being logged today has no fixed "end" yet — flow logged
/// for today keeps this walking forward one more day, landing on today
/// itself (see "A period still being logged counts as ongoing, not yet
/// ended").
DateTime lastLoggedPeriodEndDate({
  required DateTime lastPeriodStart,
  required Set<DateTime> datesWithPeriodFlow,
}) {
  final flowDates = datesWithPeriodFlow.map(dateOnly).toSet();
  var end = dateOnly(lastPeriodStart);
  var cursor = end;
  while (flowDates.contains(cursor)) {
    end = cursor;
    cursor = cursor.add(const Duration(days: 1));
  }
  return end;
}

/// Days between [now] and either the start or the (possibly still
/// extending) end of the last logged period, per [referencePoint].
int daysSinceLastPeriod({
  required DateTime lastPeriodStart,
  required Set<DateTime> datesWithPeriodFlow,
  required DateTime now,
  PeriodReferencePoint referencePoint = PeriodReferencePoint.end,
}) {
  final reference = referencePoint == PeriodReferencePoint.start
      ? dateOnly(lastPeriodStart)
      : lastLoggedPeriodEndDate(
          lastPeriodStart: lastPeriodStart,
          datesWithPeriodFlow: datesWithPeriodFlow,
        );
  return daysBetween(reference, now);
}

/// Days from [now] to the predicted next period start. Negative once the
/// predicted date has passed rather than clamping to zero — the caller
/// decides how to present an overdue period. Null with no average cycle
/// length to draw on yet (docs/features/quick_stats.feature, "Estimated
/// days to next period needs at least one complete cycle").
int? estimatedDaysToNextPeriod({
  required DateTime lastPeriodStart,
  required double? averageCycleLength,
  required DateTime now,
}) {
  final predicted = predictNextPeriodStart(
    lastPeriodStart: lastPeriodStart,
    averageCycleLength: averageCycleLength,
  );
  if (predicted == null) return null;
  return daysBetween(now, predicted);
}

/// Whether cycle-length history is too thin to show a single confident
/// number for — fewer than 2 complete cycle lengths, or the last
/// [windowSize] lengths vary by more than [thresholdDays] (see
/// docs/features/dashboard_visualizations.feature, "Gauge shows a range
/// instead of false precision when data is thin"). The same rule the
/// trend card's "never fabricates a trend" scenario uses for the
/// length-only half of its check.
bool hasThinCycleHistory(
  List<int> cycleLengths, {
  int windowSize = 3,
  int thresholdDays = 7,
}) {
  return cycleLengths.length < 2 ||
      cycleLengthsAreIrregular(
        cycleLengths,
        windowSize: windowSize,
        thresholdDays: thresholdDays,
      );
}

/// How full a gauge card should render, as a fraction of the user's own
/// average cycle length — never a fixed or generic scale (see
/// docs/features/dashboard_visualizations.feature, "the gauge fills
/// relative to the user's own average cycle length"). Clamped to [0, 1]:
/// an overdue period (more elapsed days than the average cycle length)
/// still renders as a full gauge rather than overflowing it. Null when
/// there's no average to measure against yet.
double? gaugeFillFraction({
  required int elapsedDays,
  required double? averageCycleLength,
}) {
  if (averageCycleLength == null || averageCycleLength <= 0) return null;
  final fraction = elapsedDays / averageCycleLength;
  return fraction.clamp(0.0, 1.0);
}

List<int> _lastN(List<int> values, int n) {
  if (values.length <= n) return values;
  return values.sublist(values.length - n);
}
