import 'package:inner_flare/core/providers/cycle_day_log_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'has_any_logs_provider.g.dart';

/// Whether the user has ever logged a day — distinguishes "no data yet"
/// from "nothing in this particular month" for the calendar's empty state
/// (docs/features/calendar.feature, "Empty calendar before any logging").
@riverpod
Future<bool> hasAnyLogs(Ref ref) async {
  final repository = await ref.watch(cycleDayLogRepositoryProvider.future);
  return repository.hasAnyLogs();
}
