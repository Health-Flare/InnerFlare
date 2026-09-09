import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inner_flare/core/providers/cycle_day_log_repository_provider.dart';
import 'package:inner_flare/core/providers/dashboard_card_preferences_provider.dart';
import 'package:inner_flare/core/providers/has_any_logs_provider.dart';
import 'package:inner_flare/core/providers/now_provider.dart';
import 'package:inner_flare/core/providers/today_log_provider.dart';
import 'package:inner_flare/features/calendar/screens/calendar_screen.dart';
import 'package:inner_flare/features/dashboard/greeting.dart';
import 'package:inner_flare/features/dashboard/screens/dashboard_customize_screen.dart';
import 'package:inner_flare/features/dashboard/widgets/data_preview_card.dart';
import 'package:inner_flare/features/dashboard/widgets/database_status_indicator.dart';
import 'package:inner_flare/features/dashboard/widgets/log_today_hero_card.dart';
import 'package:inner_flare/features/dashboard/widgets/privacy_reassurance_card.dart';
import 'package:inner_flare/features/dashboard/widgets/unlock_error_banner.dart';
import 'package:inner_flare/features/insights/screens/insights_screen.dart';
import 'package:inner_flare/features/log/screens/log_entry_screen.dart';
import 'package:inner_flare/features/settings/screens/settings_screen.dart';
import 'package:inner_flare/models/dashboard_card.dart';

/// The dashboard's welcoming first impression. The "log today" entry point,
/// the Calendar card, and the Insights card are all wired to the real,
/// encrypted on-device database (see lib/data/database/app_database.dart).
///
/// Which of those cards show, and in what order, is user-customizable
/// (see docs/features/dashboard.feature) via [DashboardCustomizeScreen].
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  void _openCustomize(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const DashboardCustomizeScreen()));
  }

  void _openSettings(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  /// Opens the single-screen log UI for [date] — whether that day is
  /// unlogged (starting blank) or already has an entry (pre-filled for
  /// editing). The screen itself persists every change; this only shows
  /// a confirmation once the user is done (docs/features/log.feature).
  Future<void> _openLogEntry(
    BuildContext context,
    WidgetRef ref,
    DateTime date,
  ) async {
    final isToday = _isSameDate(date, ref.read(nowProvider)());
    final repository = await ref.read(cycleDayLogRepositoryProvider.future);
    final existing = await repository.getByDate(date);
    if (!context.mounted) return;

    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => LogEntryScreen(date: date, initialLog: existing),
      ),
    );
    if (!context.mounted || saved != true) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(isToday ? 'Logged today.' : 'Saved that day.')),
      );
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Opens the calendar (docs/features/calendar.feature) — now the way to
  /// reach back-logging, since tapping any day there opens the same
  /// single-screen log UI as "Log today" (see
  /// docs/features/log.feature, "Back-logging a missed day is exactly as
  /// fast as logging today").
  void _openCalendar(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const CalendarScreen()));
  }

  /// Opens insights (docs/features/insights.feature) — always navigable;
  /// the screen itself shows the honest "not enough data yet" state when
  /// there's no history to draw statistics from.
  void _openInsights(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const InsightsScreen()));
  }

  /// Builds the [DataPreviewCard] for a customizable [card] — the one
  /// place that maps a [DashboardCard] to its icon, copy, and tap target.
  Widget _buildCard(BuildContext context, DashboardCard card, bool hasAnyLogs) {
    switch (card) {
      case DashboardCard.calendar:
        return DataPreviewCard(
          icon: Icons.calendar_month_rounded,
          title: 'Calendar',
          message: hasAnyLogs
              ? 'See every logged day, plus predicted period and '
                    'fertile windows once you have enough history.'
              : 'Nothing logged yet. Your history will show up here '
                    'the moment you log your first day.',
          onTap: () => _openCalendar(context),
        );
      case DashboardCard.insights:
        return DataPreviewCard(
          icon: Icons.insights_rounded,
          title: 'Insights',
          message: hasAnyLogs
              ? 'See your average cycle length and predictions, plus '
                    'exactly what they\'re based on.'
              : 'Not enough data yet. Log a couple of cycles and you\'ll '
                    'see predictions here, plus exactly what they\'re '
                    'based on.',
          onTap: () => _openInsights(context),
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(nowProvider)();
    final today = DateTime(now.year, now.month, now.day);
    final greeting = greetingForHour(now.hour);
    final todayLog = ref.watch(todayLogProvider);
    final isLoggedToday = todayLog.value != null;
    final isBusy = todayLog.isLoading;
    final hasAnyLogs = ref.watch(hasAnyLogsProvider).value ?? false;
    final visibleCards =
        ref
            .watch(dashboardCardPreferencesProvider)
            .value
            ?.where((pref) => pref.visible)
            .map((pref) => pref.card)
            .toList() ??
        const <DashboardCard>[];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/Inner Flare Logo.png',
              width: 28,
              height: 28,
            ),
            const SizedBox(width: 10),
            const Text('InnerFlare'),
          ],
        ),
        actions: [
          const DatabaseStatusIndicator(),
          IconButton(
            tooltip: 'Customize dashboard',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => _openCustomize(context),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _openSettings(context),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            Text(
              greeting,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'This is your space — track as much or as little as feels right.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            LogTodayHeroCard(
              isLoggedToday: isLoggedToday,
              isBusy: isBusy,
              onLogToday: () => _openLogEntry(context, ref, today),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _openCalendar(context),
                icon: const Icon(Icons.history_rounded, size: 18),
                label: const Text('Log a previous day'),
              ),
            ),
            if (todayLog.hasError) ...[
              const SizedBox(height: 12),
              UnlockErrorBanner(
                onRetry: () => retryDatabaseUnlock(ref),
                detail: todayLog.error?.toString(),
              ),
            ],
            if (visibleCards.isNotEmpty) ...[
              const SizedBox(height: 28),
              Text(
                'Your data, at a glance',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              for (final card in visibleCards) ...[
                _buildCard(context, card, hasAnyLogs),
                const SizedBox(height: 12),
              ],
            ] else
              const SizedBox(height: 28),
            const PrivacyReassuranceCard(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isBusy ? null : () => _openLogEntry(context, ref, today),
        icon: Icon(isLoggedToday ? Icons.check_rounded : Icons.add_rounded),
        label: const Text('Log today'),
      ),
    );
  }
}
