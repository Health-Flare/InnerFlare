import 'package:inner_flare/core/cycle_math/cycle_math.dart';
import 'package:inner_flare/core/providers/cycle_day_log_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cycle_prediction_provider.g.dart';

/// The predicted next period range and fertile window, derived from every
/// period-start date on record — both are estimates, never a guarantee
/// (docs/features/calendar.feature, "Predicted period and fertile window
/// are shown on the calendar").
class CyclePrediction {
  const CyclePrediction({this.periodRange, this.fertileWindow});

  /// Null until there's at least one complete prior cycle to average.
  final PredictedPeriodRange? periodRange;

  /// Null under the same condition as [periodRange] — both are derived
  /// from the same predicted next period start.
  final FertileWindow? fertileWindow;
}

@riverpod
Future<CyclePrediction> cyclePrediction(Ref ref) async {
  final repository = await ref.watch(cycleDayLogRepositoryProvider.future);
  final periodStarts = await repository.getPeriodStartDates();
  if (periodStarts.isEmpty) return const CyclePrediction();

  final lengths = cycleLengthsFromPeriodStarts(periodStarts);
  final average = averageCycleLength(lengths);
  final nextStart = predictNextPeriodStart(
    lastPeriodStart: periodStarts.last,
    averageCycleLength: average,
  );

  return CyclePrediction(
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
