import 'package:inner_flare/core/providers/cycle_day_log_repository_provider.dart';
import 'package:inner_flare/models/cycle_day_log.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cycle_day_log_entry_provider.g.dart';

/// The saved entry (if any) for a single date — backs the log-entry
/// screen for today or any prior day (docs/features/log.feature,
/// "Back-logging a missed day is exactly as fast as logging today").
///
/// [date] must be date-only (no time-of-day component) so the same
/// calendar day always resolves to the same provider instance.
@riverpod
class CycleDayLogEntry extends _$CycleDayLogEntry {
  @override
  Future<CycleDayLog?> build(DateTime date) async {
    final repository = await ref.watch(cycleDayLogRepositoryProvider.future);
    return repository.getByDate(date);
  }

  /// Persists [log], replacing any existing entry for [date] — the
  /// repository upserts by date, so there is only ever one row per date
  /// (docs/features/log.feature, "Editing an existing day's log").
  Future<void> save(CycleDayLog log) async {
    // ignore: invalid_use_of_internal_member
    state = const AsyncLoading<CycleDayLog?>().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      final repository = await ref.read(cycleDayLogRepositoryProvider.future);
      return repository.save(log);
    });
  }
}
