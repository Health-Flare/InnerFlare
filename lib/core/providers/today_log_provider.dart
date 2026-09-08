import 'package:inner_flare/core/providers/cycle_day_log_repository_provider.dart';
import 'package:inner_flare/core/providers/now_provider.dart';
import 'package:inner_flare/models/cycle_day_log.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'today_log_provider.g.dart';

/// Whether — and how — today has been logged. Backs the dashboard's
/// persistent "log today" entry point (docs/features/log.feature).
@riverpod
class TodayLog extends _$TodayLog {
  @override
  Future<CycleDayLog?> build() async {
    final repository = await ref.watch(cycleDayLogRepositoryProvider.future);
    final now = ref.watch(nowProvider);
    return repository.getByDate(now());
  }

  /// Confirms today with zero required input — a tap-and-done entry with
  /// no period flow, no symptoms, and no note. Saving a second time for
  /// the same day is a no-op: there is only ever one row per date, and
  /// this entry point never overwrites data a real edit flow later adds.
  Future<void> logToday() async {
    state = const AsyncLoading<CycleDayLog?>().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      final repository = await ref.read(cycleDayLogRepositoryProvider.future);
      final now = ref.read(nowProvider)();
      final existing = await repository.getByDate(now);
      return existing ?? await repository.save(CycleDayLog(date: now));
    });
  }
}
