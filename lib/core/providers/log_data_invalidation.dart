import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inner_flare/core/providers/calendar_month_logs_provider.dart';
import 'package:inner_flare/core/providers/cycle_day_log_entry_provider.dart';
import 'package:inner_flare/core/providers/cycle_insights_provider.dart';
import 'package:inner_flare/core/providers/cycle_prediction_provider.dart';
import 'package:inner_flare/core/providers/dashboard_visualization_displays_provider.dart';
import 'package:inner_flare/core/providers/has_any_logs_provider.dart';
import 'package:inner_flare/core/providers/today_log_provider.dart';

/// Invalidates every provider that reads from `cycle_day_logs` (directly
/// or transitively): every one of them does a one-shot read of the
/// repository rather than watching a live stream, so none of them notice
/// a write on their own (see cycle_day_log_repository_provider.dart:
/// `cycleDayLogRepositoryProvider` itself never changes identity when the
/// data underneath it does).
///
/// Call this after *any* write to the log: a single day saved from the
/// log-entry screen, a back-logged day from the calendar, a whole backup
/// imported, or debug demo data loaded, so the dashboard's quick stats,
/// gauge cards, and trend charts (docs/features/dashboard_visualizations
/// .feature), plus Insights and the calendar, all reflect it immediately
/// instead of only after some unrelated action forces a rebuild.
void invalidateLogDependentProviders(WidgetRef ref) {
  ref
    ..invalidate(todayLogProvider)
    ..invalidate(hasAnyLogsProvider)
    ..invalidate(cycleInsightsProvider)
    ..invalidate(cyclePredictionProvider)
    ..invalidate(calendarMonthLogsProvider)
    ..invalidate(cycleDayLogEntryProvider)
    ..invalidate(gaugeCardDisplayProvider)
    ..invalidate(trendCardDisplayProvider)
    ..invalidate(quickStatCardDisplayProvider);
}
