/// Pure cycle statistics: no Flutter, no database, no `DateTime.now()`.
///
/// Every "now" this module needs is passed in by the caller so results are
/// deterministic and exhaustively unit-testable (see docs/features/insights.feature).
library;

import 'dart:math' as math;

import 'package:inner_flare/models/period_flow.dart';

/// Normalizes a date to UTC midnight so day-count math is never skewed by
/// daylight saving time transitions in the local timezone.
DateTime dateOnly(DateTime date) {
  return DateTime.utc(date.year, date.month, date.day);
}

/// Whole days between two dates, DST-safe.
int daysBetween(DateTime from, DateTime to) {
  return dateOnly(to).difference(dateOnly(from)).inDays;
}

/// The longest run of days with nothing logged (or no flow logged) that
/// still counts as part of the same period: one day. A user who forgets
/// to log a single day mid-period should not get a 3-day "cycle".
const int maxDaysWithoutFlowInsidePeriod = 1;

/// Every period start in [flowByDate], oldest first, worked out from the
/// whole log at once, so the answer never depends on the order days were
/// saved in (issue #101, docs/features/log.feature).
///
/// Flow days (spotting included) separated by at most
/// [maxDaysWithoutFlowInsidePeriod] days without flow belong to one
/// bleeding episode. The episode's period start, cycle day 1, is its first
/// day of light, medium or heavy flow, following the clinical convention
/// that a cycle runs from the first day of bleeding, not spotting
/// (FIGO 2023; Bull et al. 2019). An episode of spotting alone starts no
/// period.
List<DateTime> periodStartsFromFlowLog(Map<DateTime, PeriodFlow> flowByDate) {
  final flowByDay = <DateTime, PeriodFlow>{
    for (final entry in flowByDate.entries) dateOnly(entry.key): entry.value,
  };
  final days = flowByDay.keys.toList()..sort();

  final starts = <DateTime>[];
  DateTime? previousFlowDay;
  var episodeHasStart = false;
  for (final day in days) {
    final newEpisode =
        previousFlowDay == null ||
        daysBetween(previousFlowDay, day) > maxDaysWithoutFlowInsidePeriod + 1;
    if (newEpisode) episodeHasStart = false;
    if (!episodeHasStart && flowByDay[day] != PeriodFlow.spotting) {
      starts.add(day);
      episodeHasStart = true;
    }
    previousFlowDay = day;
  }
  return starts;
}

/// Cycle lengths (in days) between each consecutive pair of period start
/// dates. [periodStarts] need not be sorted or deduplicated.
///
/// A single period start produces no complete cycle length yet. The app
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
/// Returns null with fewer than 2 cycle lengths: variability is undefined
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
/// day itself, the six-day window measured by Wilcox et al. (NEJM 1995).
/// Sources and their caveats: lib/core/citations/medical_sources.dart.
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

/// Average luteal phase length (ACOG: ovulation about 14 days before the
/// next period). Real cycles range from about 7 to 19 days and a large
/// app-based study measured a mean of 12.4, so this is a population
/// average, not a clinical constant; see
/// lib/core/citations/medical_sources.dart. Used until the user
/// sets their own value in settings (docs/features/insights.feature covers
/// the settings surface; not yet implemented).
const int defaultLutealPhaseLengthDays = 14;

/// Typical period length (ACOG: up to 7 days; mean bleed length 4.0 days in
/// Bull et al. 2019), used until the app
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
/// from each other (max - min). 7 days is the stricter end of the ACOG/FIGO
/// regularity limit (7 to 9 days depending on age), applied to everyone;
/// see lib/core/citations/medical_sources.dart. Per
/// docs/features/insights.feature,
/// "Irregular cycles still produce an average, clearly caveated". Fewer than
/// 2 cycle lengths in the window can't be irregular: there's nothing to vary
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

/// Which point in a period `daysSinceLastPeriod` measures from; see
/// docs/features/quick_stats.feature.
enum PeriodReferencePoint { start, end }

/// The last day of period flow (spotting included) in the bleeding
/// episode that begins at [lastPeriodStart], walking forward through
/// [datesWithPeriodFlow]. A gap of up to [maxDaysWithoutFlowInsidePeriod]
/// days without flow is stepped over, the same rule
/// [periodStartsFromFlowLog] uses, so one forgotten day doesn't end the
/// period early. A longer gap stops the walk, so an unrelated later
/// logged day (e.g. the start of a *different* period) is never swept in.
///
/// A period still being logged today has no fixed "end" yet. Flow logged
/// for today keeps this walking forward one more day, landing on today
/// itself (see "A period still being logged counts as ongoing, not yet
/// ended").
DateTime lastLoggedPeriodEndDate({
  required DateTime lastPeriodStart,
  required Set<DateTime> datesWithPeriodFlow,
}) {
  final flowDates = datesWithPeriodFlow.map(dateOnly).toSet();
  var end = dateOnly(lastPeriodStart);
  var advanced = true;
  while (advanced) {
    advanced = false;
    for (var step = 1; step <= maxDaysWithoutFlowInsidePeriod + 1; step++) {
      final next = end.add(Duration(days: step));
      if (flowDates.contains(next)) {
        end = next;
        advanced = true;
        break;
      }
    }
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
/// predicted date has passed rather than clamping to zero. The caller
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
/// number for: fewer than 2 complete cycle lengths, or the last
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
/// average cycle length, never a fixed or generic scale (see
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

/// One row of the cycle-by-cycle detail table (docs/features/
/// dashboard_visualizations.feature, "The cycle detail table lists every
/// complete cycle and the gap since the one before it"), intended to be
/// reviewed quickly, e.g. ahead of a healthcare provider conversation.
class CycleDetailRow {
  const CycleDetailRow({
    required this.start,
    required this.lengthDays,
    required this.differenceFromPreviousDays,
  });

  /// The date this complete cycle started.
  final DateTime start;

  /// This cycle's length: days from [start] until the next period start.
  final int lengthDays;

  /// Signed difference from the cycle immediately before this one
  /// ([lengthDays] minus that cycle's length). Null for the oldest
  /// complete cycle on record. There's nothing earlier to compare it to.
  final int? differenceFromPreviousDays;
}

/// Every complete cycle derived from [periodStarts], most-recent-first,
/// deliberately the opposite order from the trend chart itself, which
/// stays chronological (oldest-first) so it reads naturally left to
/// right. Empty with fewer than 2 period starts, same as
/// [cycleLengthsFromPeriodStarts] (there's no complete cycle yet).
List<CycleDetailRow> cycleDetailRows(Iterable<DateTime> periodStarts) {
  final sorted = periodStarts.map(dateOnly).toSet().toList()..sort();
  if (sorted.length < 2) return const [];

  final lengths = [
    for (var i = 1; i < sorted.length; i++)
      daysBetween(sorted[i - 1], sorted[i]),
  ];

  return [
    for (var i = lengths.length - 1; i >= 0; i--)
      CycleDetailRow(
        start: sorted[i],
        lengthDays: lengths[i],
        differenceFromPreviousDays: i == 0 ? null : lengths[i] - lengths[i - 1],
      ),
  ];
}

List<int> _lastN(List<int> values, int n) {
  if (values.length <= n) return values;
  return values.sublist(values.length - n);
}
