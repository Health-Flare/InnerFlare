import 'package:inner_flare/models/cycle_day_log.dart';
import 'package:inner_flare/models/period_flow.dart';

/// A day with no period flow and no symptoms — the "confirm with zero
/// input" case from docs/features/log.feature.
CycleDayLog emptyLog({DateTime? date}) {
  return CycleDayLog(date: date ?? DateTime.utc(2026, 1, 1));
}

/// A period start day with the given flow (defaults to medium).
CycleDayLog periodStartLog({
  required DateTime date,
  PeriodFlow flow = PeriodFlow.medium,
}) {
  return CycleDayLog(date: date, periodFlow: flow, isPeriodStart: true);
}

/// A regular 28-day cycle's worth of period-start dates, starting from
/// [firstStart], for [cycleCount] cycles.
List<DateTime> regularPeriodStarts({
  required DateTime firstStart,
  required int cycleCount,
  int cycleLengthDays = 28,
}) {
  return [
    for (var i = 0; i < cycleCount; i++)
      firstStart.add(Duration(days: cycleLengthDays * i)),
  ];
}

/// A day logged with symptoms only, no period flow.
CycleDayLog symptomOnlyLog({
  required DateTime date,
  Set<String> symptoms = const {'cramps', 'fatigue'},
}) {
  return CycleDayLog(date: date, symptoms: symptoms);
}
