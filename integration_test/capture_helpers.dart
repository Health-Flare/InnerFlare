// Shared by integration_test/screenshot_test.dart and video_test.dart:
// the fixed clock and the seeding steps from docs/marketing/specs/
// (datasets.yaml), so both produce the same data on the real on-device
// database.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inner_flare/core/debug/demo_data.dart';
import 'package:inner_flare/core/providers/calendar_month_logs_provider.dart';
import 'package:inner_flare/core/providers/cycle_day_log_entry_provider.dart';
import 'package:inner_flare/core/providers/cycle_day_log_repository_provider.dart';
import 'package:inner_flare/core/providers/cycle_insights_provider.dart';
import 'package:inner_flare/core/providers/cycle_prediction_provider.dart';
import 'package:inner_flare/core/providers/dashboard_card_preferences_provider.dart';
import 'package:inner_flare/core/providers/dashboard_card_preferences_repository_provider.dart';
import 'package:inner_flare/core/providers/has_any_logs_provider.dart';
import 'package:inner_flare/core/providers/now_provider.dart';
import 'package:inner_flare/core/providers/today_log_provider.dart';
import 'package:inner_flare/models/dashboard_card.dart';

/// The fixed clock from docs/marketing/specs/datasets.yaml, so the seeded
/// history, predictions and the calendar's month never drift between runs.
final fixedNow = DateTime(2026, 9, 25, 9, 41);

/// Seeds [buildDemoCycleLogs] through the real repository, oldest first,
/// then invalidates every provider that reads from it, same as
/// lib/features/settings/screens/settings_screen.dart's debug-only
/// "Load demo data" button, just driven directly from the test instead
/// of tapping through Settings. Returns the most recent period's start
/// date, so the caller can show [LogEntryScreen] for a day that actually
/// has something logged.
Future<DateTime> seedDemoData(ProviderContainer container) async {
  final repository = await container.read(cycleDayLogRepositoryProvider.future);
  await repository.deleteAll();
  final now = container.read(nowProvider)();
  final logs = buildDemoCycleLogs(now: now)
    ..sort((a, b) => a.date.compareTo(b.date));
  for (final log in logs) {
    await repository.save(log);
  }

  invalidateLogDependentProviders(container);

  // isPeriodStart is computed by the repository on save, not set on the
  // generator's own CycleDayLog values (which default it to false). Ask
  // the repository, the authoritative source, rather than guessing which
  // of [logs] became a period start.
  final periodStarts = await repository.getPeriodStartDates();
  return periodStarts.last;
}

void invalidateLogDependentProviders(ProviderContainer container) {
  container.invalidate(todayLogProvider);
  container.invalidate(hasAnyLogsProvider);
  container.invalidate(cycleInsightsProvider);
  container.invalidate(cyclePredictionProvider);
  container.invalidate(calendarMonthLogsProvider);
  container.invalidate(cycleDayLogEntryProvider);
}

/// Builds a dashboard layout (docs/marketing/specs/datasets.yaml `layouts`):
/// the fresh-install default, or, if [customized], one that actually shows
/// off customization (a gauge card, a trend card, and Calendar widened to
/// full width) instead of the bare four-cell default (see
/// docs/features/dashboard_grid_layout.feature, "A card's cell size can
/// be adjusted from Customize dashboard"). Saved through the same
/// repository real customization goes through, then invalidates the
/// provider that reads it, same pattern as [seedDemoData].
///
/// Drops any gauge/trend cards already present first: this runs against
/// the real on-device database (see the file comment above), which may
/// carry state left over from a previous run or from manually using the
/// app on this device/simulator, so the layout this produces is the same
/// regardless of what was there before.
Future<void> seedDashboardLayout(
  ProviderContainer container, {
  required bool customized,
}) async {
  final repository = await container.read(
    dashboardCardPreferencesRepositoryProvider.future,
  );
  if (!customized) {
    // saveAll replaces the whole layout: an empty one falls back to the
    // fresh-install defaults on the next getAll().
    await repository.saveAll(const []);
    container.invalidate(dashboardCardPreferencesProvider);
    return;
  }
  final current = await repository.getAll();
  final withCalendarWidened = [
    for (final instance in current)
      if (instance.kind != DashboardCardKind.gauge &&
          instance.kind != DashboardCardKind.trend)
        if (instance.id == 'calendar')
          instance.withGridSpan(columnSpan: dashboardGridMaxColumnSpan)
        else
          instance,
  ];
  final gauge = newGaugeCardInstance(
    order: withCalendarWidened.length,
    mode: GaugeCardMode.estimatedDaysUntilNextPeriod,
  );
  final trend = newTrendCardInstance(
    order: withCalendarWidened.length + 1,
    metric: TrendCardMetric.previousCycleLengths,
    chartType: TrendChartType.line,
  ).withGridSpan(rowSpan: 2);

  await repository.saveAll([...withCalendarWidened, gauge, trend]);
  container.invalidate(dashboardCardPreferencesProvider);
}
