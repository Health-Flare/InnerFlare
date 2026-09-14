import 'package:inner_flare/core/cycle_math/cycle_math.dart' as cycle_math;
import 'package:inner_flare/core/providers/cycle_day_log_repository_provider.dart';
import 'package:inner_flare/core/providers/now_provider.dart';
import 'package:inner_flare/core/providers/quick_stat_preferences_provider.dart';
import 'package:inner_flare/models/quick_stat.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'quick_stat_displays_provider.g.dart';

/// One quick stat slot, resolved to a concrete value for display. [value]
/// is null when there isn't enough history yet — see
/// docs/features/quick_stats.feature, "No period ever logged..." and
/// "Estimated days to next period needs at least one complete cycle".
/// Negative for [QuickStatType.estimatedDaysToNextPeriod] once the
/// predicted date has passed; the widget layer decides how to present
/// that as "overdue" rather than a bare negative number.
class QuickStatDisplay {
  const QuickStatDisplay({
    required this.type,
    required this.referencePoint,
    required this.value,
  });

  final QuickStatType type;
  final QuickStatReferencePoint referencePoint;
  final int? value;
}

/// Computes both slots' display values live from the same period-start
/// and cycle-length data as docs/features/insights.feature — no separate
/// cached calculation to keep in sync (see "Quick stats recompute live
/// from the same data as Insights").
@riverpod
Future<List<QuickStatDisplay>> quickStatDisplays(Ref ref) async {
  final prefs = await ref.watch(quickStatPreferencesProvider.future);
  final repository = await ref.watch(cycleDayLogRepositoryProvider.future);
  final now = ref.watch(nowProvider)();

  final periodStarts = await repository.getPeriodStartDates();
  final datesWithFlow = await repository.getDatesWithPeriodFlow();
  final lastPeriodStart = periodStarts.isEmpty ? null : periodStarts.last;
  final average = cycle_math.averageCycleLength(
    cycle_math.cycleLengthsFromPeriodStarts(periodStarts),
  );

  return [
    for (final pref in prefs)
      QuickStatDisplay(
        type: pref.type,
        referencePoint: pref.referencePoint,
        value: lastPeriodStart == null
            ? null
            : switch (pref.type) {
                QuickStatType.daysSinceLastPeriod =>
                  cycle_math.daysSinceLastPeriod(
                    lastPeriodStart: lastPeriodStart,
                    datesWithPeriodFlow: datesWithFlow,
                    now: now,
                    referencePoint:
                        pref.referencePoint ==
                            QuickStatReferencePoint.periodStart
                        ? cycle_math.PeriodReferencePoint.start
                        : cycle_math.PeriodReferencePoint.end,
                  ),
                QuickStatType.estimatedDaysToNextPeriod =>
                  cycle_math.estimatedDaysToNextPeriod(
                    lastPeriodStart: lastPeriodStart,
                    averageCycleLength: average,
                    now: now,
                  ),
              },
      ),
  ];
}
