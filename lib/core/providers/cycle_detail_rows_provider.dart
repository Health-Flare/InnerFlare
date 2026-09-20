import 'package:inner_flare/core/cycle_math/cycle_math.dart' as cycle_math;
import 'package:inner_flare/core/providers/cycle_day_log_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cycle_detail_rows_provider.g.dart';

/// Every complete cycle, most-recent-first, backing the cycle detail
/// table (docs/features/dashboard_visualizations.feature, "The cycle
/// detail table lists every complete cycle..."). Shared by both trend
/// cards that lead here — see [CycleDetailScreen] — since they present
/// the same underlying period-start data two different ways.
@riverpod
Future<List<cycle_math.CycleDetailRow>> cycleDetailRows(Ref ref) async {
  final repository = await ref.watch(cycleDayLogRepositoryProvider.future);
  final periodStarts = await repository.getPeriodStartDates();
  return cycle_math.cycleDetailRows(periodStarts);
}
