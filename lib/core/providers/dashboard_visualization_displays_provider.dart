import 'package:inner_flare/core/cycle_math/cycle_math.dart' as cycle_math;
import 'package:inner_flare/core/providers/cycle_day_log_repository_provider.dart';
import 'package:inner_flare/core/providers/now_provider.dart';
import 'package:inner_flare/models/dashboard_card.dart';
import 'package:inner_flare/models/quick_stat.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dashboard_visualization_displays_provider.g.dart';

/// A gauge card resolved to concrete display values, per
/// docs/features/dashboard_visualizations.feature. [value] and
/// [fillFraction] are both null when there's no logged period yet;
/// [isThinHistory] distinguishes "no prediction to show" from "there's a
/// number, but treat it as a range/estimate, not a precise one" (see
/// "Gauge shows a range instead of false precision when data is thin").
class GaugeCardDisplay {
  const GaugeCardDisplay({
    required this.mode,
    required this.value,
    required this.fillFraction,
    required this.isThinHistory,
  });

  final GaugeCardMode mode;
  final int? value;
  final double? fillFraction;
  final bool isThinHistory;
}

/// A trend card resolved to concrete display values. [cycleLengths] is
/// oldest-first, matching chronological order per "each bar represents one
/// complete cycle length in chronological order". [averageCycleLength] is
/// null (and [hasEnoughHistory] false) with fewer than 2 complete cycles,
/// per "Trend chart never fabricates a trend from insufficient history".
class TrendCardDisplay {
  const TrendCardDisplay({
    required this.metric,
    required this.chartType,
    required this.cycleLengths,
    required this.averageCycleLength,
    required this.hasEnoughHistory,
  });

  final TrendCardMetric metric;
  final TrendChartType chartType;
  final List<int> cycleLengths;
  final double? averageCycleLength;
  final bool hasEnoughHistory;
}

/// Resolves [instance] (a gauge card) to its live display values, computed
/// from the same period-start data as docs/features/insights.feature and
/// docs/features/quick_stats.feature: no separate cached calculation to
/// drift out of sync.
@riverpod
Future<GaugeCardDisplay> gaugeCardDisplay(
  Ref ref,
  DashboardCardInstance instance,
) async {
  assert(instance.kind == DashboardCardKind.gauge);
  final mode = instance.gaugeMode;
  final repository = await ref.watch(cycleDayLogRepositoryProvider.future);
  final now = ref.watch(nowProvider)();

  final periodStarts = await repository.getPeriodStartDates();
  if (periodStarts.isEmpty) {
    return GaugeCardDisplay(
      mode: mode,
      value: null,
      fillFraction: null,
      isThinHistory: true,
    );
  }

  final lastPeriodStart = periodStarts.last;
  final cycleLengths = cycle_math.cycleLengthsFromPeriodStarts(periodStarts);
  final average = cycle_math.averageCycleLength(cycleLengths);
  final datesWithFlow = await repository.getDatesWithPeriodFlow();

  final daysSince = cycle_math.daysSinceLastPeriod(
    lastPeriodStart: lastPeriodStart,
    datesWithPeriodFlow: datesWithFlow,
    now: now,
    referencePoint: cycle_math.PeriodReferencePoint.start,
  );

  final value = switch (mode) {
    GaugeCardMode.daysSinceLastPeriod => daysSince,
    GaugeCardMode.estimatedDaysUntilNextPeriod =>
      cycle_math.estimatedDaysToNextPeriod(
        lastPeriodStart: lastPeriodStart,
        averageCycleLength: average,
        now: now,
      ),
  };

  return GaugeCardDisplay(
    mode: mode,
    value: value,
    fillFraction: cycle_math.gaugeFillFraction(
      elapsedDays: daysSince,
      averageCycleLength: average,
    ),
    isThinHistory: cycle_math.hasThinCycleHistory(cycleLengths),
  );
}

/// Resolves [instance] (a trend card) to its live display values. Only
/// [TrendCardMetric.previousCycleLengths] has real data behind it today;
/// see the TODO on [TrendCardMetric] in lib/models/dashboard_card.dart for
/// what the other catalog entries still need before they can compute
/// anything.
@riverpod
Future<TrendCardDisplay> trendCardDisplay(
  Ref ref,
  DashboardCardInstance instance,
) async {
  assert(instance.kind == DashboardCardKind.trend);
  final metric = instance.trendMetric;
  final repository = await ref.watch(cycleDayLogRepositoryProvider.future);

  if (!metric.isImplemented) {
    return TrendCardDisplay(
      metric: metric,
      chartType: instance.trendChartType,
      cycleLengths: const [],
      averageCycleLength: null,
      hasEnoughHistory: false,
    );
  }

  final periodStarts = await repository.getPeriodStartDates();
  final cycleLengths = cycle_math.cycleLengthsFromPeriodStarts(periodStarts);

  return TrendCardDisplay(
    metric: metric,
    chartType: instance.trendChartType,
    cycleLengths: cycleLengths,
    averageCycleLength: cycle_math.averageCycleLength(cycleLengths),
    hasEnoughHistory: cycleLengths.length >= 2,
  );
}

/// A quick stat card resolved to a concrete value, per
/// docs/features/quick_stats.feature. [value] is null when there isn't
/// enough history yet ("No period ever logged...", "Estimated days to
/// next period needs at least one complete cycle"). Negative for
/// [QuickStatType.estimatedDaysToNextPeriod] once the predicted date has
/// passed; the widget layer decides how to present that as "overdue"
/// rather than a bare negative number.
class QuickStatCardDisplay {
  const QuickStatCardDisplay({
    required this.type,
    required this.referencePoint,
    required this.value,
  });

  final QuickStatType type;
  final QuickStatReferencePoint referencePoint;
  final int? value;
}

/// Resolves [instance] (a quick stat card) to its live display value,
/// from the same period-start and cycle-length data as
/// docs/features/insights.feature: no separate cached calculation to
/// keep in sync (see "Quick stats recompute live from the same data as
/// Insights").
@riverpod
Future<QuickStatCardDisplay> quickStatCardDisplay(
  Ref ref,
  DashboardCardInstance instance,
) async {
  assert(instance.kind == DashboardCardKind.quickStat);
  final type = instance.quickStatType;
  final referencePoint = instance.quickStatReferencePoint;
  final repository = await ref.watch(cycleDayLogRepositoryProvider.future);
  final now = ref.watch(nowProvider)();

  final periodStarts = await repository.getPeriodStartDates();
  if (periodStarts.isEmpty) {
    return QuickStatCardDisplay(
      type: type,
      referencePoint: referencePoint,
      value: null,
    );
  }

  final lastPeriodStart = periodStarts.last;
  final datesWithFlow = await repository.getDatesWithPeriodFlow();
  final average = cycle_math.averageCycleLength(
    cycle_math.cycleLengthsFromPeriodStarts(periodStarts),
  );

  final value = switch (type) {
    QuickStatType.daysSinceLastPeriod => cycle_math.daysSinceLastPeriod(
      lastPeriodStart: lastPeriodStart,
      datesWithPeriodFlow: datesWithFlow,
      now: now,
      referencePoint: referencePoint == QuickStatReferencePoint.periodStart
          ? cycle_math.PeriodReferencePoint.start
          : cycle_math.PeriodReferencePoint.end,
    ),
    QuickStatType.estimatedDaysToNextPeriod =>
      cycle_math.estimatedDaysToNextPeriod(
        lastPeriodStart: lastPeriodStart,
        averageCycleLength: average,
        now: now,
      ),
  };

  return QuickStatCardDisplay(
    type: type,
    referencePoint: referencePoint,
    value: value,
  );
}
