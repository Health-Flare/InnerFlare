import 'package:inner_flare/core/providers/cycle_day_log_entry_provider.dart';
import 'package:inner_flare/core/providers/now_provider.dart';
import 'package:inner_flare/models/cycle_day_log.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'today_log_provider.g.dart';

/// Whether — and how — today has been logged. A thin wrapper over
/// [cycleDayLogEntryProvider] for today's date; backs the dashboard's
/// persistent "log today" entry point (docs/features/log.feature).
@riverpod
Future<CycleDayLog?> todayLog(Ref ref) async {
  final now = ref.watch(nowProvider)();
  final today = DateTime(now.year, now.month, now.day);
  return ref.watch(cycleDayLogEntryProvider(today).future);
}
