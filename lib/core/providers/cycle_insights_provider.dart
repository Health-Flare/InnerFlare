import 'dart:math' as math;

import 'package:inner_flare/core/cycle_math/cycle_math.dart';
import 'package:inner_flare/core/providers/cycle_day_log_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cycle_insights_provider.g.dart';

/// Everything the insights screen needs to render transparent statistics
/// and estimates, per docs/features/insights.feature. Deliberately not
/// persisted anywhere: it's recomputed live from period-start dates on
/// every read, so an edited past log is reflected immediately with no
/// separate cached row to keep in sync (see "Insights recompute live").
///
/// Uses the fixed cycle history window (6) and luteal phase length (14)
/// from cycle_math.dart. Making them user settings is issue #37; the
/// calendar and dashboard providers use the same defaults and would need
/// the same change.
class CycleInsights {
  const CycleInsights({
    required this.periodStartsLogged,
    required this.cycleLengths,
    required this.averageCycleLength,
    required this.variability,
    required this.isIrregular,
    this.nextPeriodStart,
    this.periodRange,
    this.fertileWindow,
  });

  /// Total period-start dates on record, oldest first in [cycleLengths]'s
  /// derivation order. Used to distinguish "never logged a start" from
  /// "logged exactly one, no prior cycle yet" from "enough for an average".
  final int periodStartsLogged;

  /// Complete cycle lengths (days between consecutive period starts),
  /// oldest first. Empty until there are at least 2 period starts.
  final List<int> cycleLengths;

  /// Mean of the last N cycle lengths. Null until there's at least 1
  /// complete cycle length.
  final double? averageCycleLength;

  /// Population standard deviation of the last N cycle lengths. Null with
  /// fewer than 2 complete cycle lengths; shown once there are >= 3 per
  /// the feature file, since 2 lengths make variability technically
  /// defined but not yet a meaningful signal.
  final double? variability;

  /// Whether the last few cycle lengths vary enough to call out explicitly
  /// rather than presenting the average as if cycles were perfectly
  /// regular.
  final bool isIrregular;

  final DateTime? nextPeriodStart;
  final PredictedPeriodRange? periodRange;
  final FertileWindow? fertileWindow;

  /// No period start ever logged: the "not enough data yet" empty state,
  /// with no fabricated estimate of any kind.
  bool get hasNoHistory => periodStartsLogged == 0;

  /// Exactly one period start logged: there's a start date, but no prior
  /// cycle to measure a length from yet.
  bool get needsSecondCycle => periodStartsLogged == 1;

  /// How many cycle lengths [averageCycleLength] is actually based on:
  /// the most recent [defaultCycleHistoryWindow], or all of them if there
  /// are fewer. What the "Based on your last N cycles" caveat must say.
  int get cyclesInAverage =>
      math.min(cycleLengths.length, defaultCycleHistoryWindow);

  /// >= 3 complete cycle lengths: enough for variability to mean anything.
  bool get hasVariabilityData => cycleLengths.length >= 3;
}

@riverpod
Future<CycleInsights> cycleInsights(Ref ref) async {
  final repository = await ref.watch(cycleDayLogRepositoryProvider.future);
  final periodStarts = await repository.getPeriodStartDates();

  final lengths = cycleLengthsFromPeriodStarts(periodStarts);
  final average = averageCycleLength(lengths);
  final variability = cycleLengthVariability(lengths);
  final nextStart = periodStarts.isEmpty
      ? null
      : predictNextPeriodStart(
          lastPeriodStart: periodStarts.last,
          averageCycleLength: average,
        );

  return CycleInsights(
    periodStartsLogged: periodStarts.length,
    cycleLengths: lengths,
    averageCycleLength: average,
    variability: variability,
    isIrregular: cycleLengthsAreIrregular(lengths),
    nextPeriodStart: nextStart,
    periodRange: predictNextPeriodRange(
      nextPeriodStart: nextStart,
      periodLengthDays: defaultPeriodLengthDays,
    ),
    fertileWindow: predictFertileWindow(
      nextPeriodStart: nextStart,
      lutealPhaseLengthDays: defaultLutealPhaseLengthDays,
    ),
  );
}
