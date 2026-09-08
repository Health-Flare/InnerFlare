import 'package:inner_flare/core/providers/cycle_day_log_repository_provider.dart';
import 'package:inner_flare/models/cycle_day_log.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'calendar_month_logs_provider.g.dart';

/// Every logged day in the month containing [month], keyed by date-only —
/// backs the calendar's month view (docs/features/calendar.feature).
///
/// [month] must be the first of the month (no time-of-day component) so
/// the same month always resolves to the same provider instance.
@riverpod
Future<Map<DateTime, CycleDayLog>> calendarMonthLogs(
  Ref ref,
  DateTime month,
) async {
  final repository = await ref.watch(cycleDayLogRepositoryProvider.future);
  final start = DateTime(month.year, month.month, 1);
  final end = DateTime(month.year, month.month + 1, 0);
  final logs = await repository.getInRange(start, end);
  return {for (final log in logs) log.date: log};
}
