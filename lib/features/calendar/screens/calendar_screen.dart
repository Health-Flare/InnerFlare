import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inner_flare/core/providers/calendar_month_logs_provider.dart';
import 'package:inner_flare/core/providers/cycle_day_log_repository_provider.dart';
import 'package:inner_flare/core/providers/cycle_prediction_provider.dart';
import 'package:inner_flare/core/providers/has_any_logs_provider.dart';
import 'package:inner_flare/core/providers/now_provider.dart';
import 'package:inner_flare/core/theme/app_theme.dart';
import 'package:inner_flare/features/calendar/widgets/calendar_legend.dart';
import 'package:inner_flare/features/calendar/widgets/calendar_month_grid.dart';
import 'package:inner_flare/features/log/screens/log_entry_screen.dart';

/// The calendar/history view (docs/features/calendar.feature): a month
/// grid marking period days, symptom-only days, and — once there's at
/// least one complete prior cycle — the predicted next period and fertile
/// window. Tapping any day, past or future, opens the same single-screen
/// log UI used from the dashboard.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    final now = ref.read(nowProvider)();
    _visibleMonth = DateTime(now.year, now.month, 1);
  }

  void _goToPreviousMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1, 1);
    });
  }

  void _goToNextMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 1);
    });
  }

  void _goToToday(DateTime today) {
    setState(() {
      _visibleMonth = DateTime(today.year, today.month, 1);
    });
  }

  Future<void> _openLogEntry(DateTime date) async {
    final repository = await ref.read(cycleDayLogRepositoryProvider.future);
    final existing = await repository.getByDate(date);
    if (!mounted) return;

    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => LogEntryScreen(date: date, initialLog: existing),
      ),
    );
    if (saved != true) return;

    ref
      ..invalidate(calendarMonthLogsProvider)
      ..invalidate(cyclePredictionProvider)
      ..invalidate(hasAnyLogsProvider);
  }

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(nowProvider)();
    final today = DateTime(now.year, now.month, now.day);
    final monthLogs = ref.watch(calendarMonthLogsProvider(_visibleMonth));
    final prediction = ref.watch(cyclePredictionProvider);
    final hasAnyLogs = ref.watch(hasAnyLogsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${_months[_visibleMonth.month - 1]} ${_visibleMonth.year}',
        ),
        actions: [
          IconButton(
            tooltip: 'Today',
            icon: const Icon(Icons.today_rounded),
            onPressed: () => _goToToday(today),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  tooltip: 'Previous month',
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: _goToPreviousMonth,
                ),
                IconButton(
                  tooltip: 'Next month',
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: _goToNextMonth,
                ),
              ],
            ),
            switch (monthLogs) {
              AsyncData(:final value) => CalendarMonthGrid(
                month: _visibleMonth,
                logsByDate: value,
                prediction: prediction.value ?? const CyclePrediction(),
                today: today,
                onDayTap: _openLogEntry,
              ),
              AsyncError() => const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Text("Couldn't load this month. Try again."),
              ),
              _ => const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              ),
            },
            const SizedBox(height: 20),
            const CalendarLegend(),
            if (hasAnyLogs.value == false) ...[
              const SizedBox(height: 28),
              Text(
                "Nothing logged yet — tap any day above to add your first "
                'entry.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.deepTeal.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
