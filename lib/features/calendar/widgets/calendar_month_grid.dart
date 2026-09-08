import 'package:flutter/material.dart';
import 'package:inner_flare/core/providers/cycle_prediction_provider.dart';
import 'package:inner_flare/core/theme/app_theme.dart';
import 'package:inner_flare/features/calendar/widgets/calendar_day_cell.dart';
import 'package:inner_flare/models/cycle_day_log.dart';

/// A full-weeks grid (Monday-first) for the month containing [month],
/// including the leading/trailing days of adjacent months needed to fill
/// each week — those are still tappable (docs/features/calendar.feature,
/// "the user taps any date, past or future").
class CalendarMonthGrid extends StatelessWidget {
  const CalendarMonthGrid({
    super.key,
    required this.month,
    required this.logsByDate,
    required this.prediction,
    required this.today,
    required this.onDayTap,
  });

  final DateTime month;
  final Map<DateTime, CycleDayLog> logsByDate;
  final CyclePrediction prediction;
  final DateTime today;
  final ValueChanged<DateTime> onDayTap;

  static const _weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final days = _daysGrid(month);

    return Column(
      children: [
        Row(
          children: [
            for (final label in _weekdayLabels)
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.deepTeal.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final day in days)
              CalendarDayCell(
                date: day,
                log: logsByDate[day],
                isCurrentMonth: day.month == month.month,
                isToday: _isSameDate(day, today),
                isPredictedPeriod:
                    prediction.periodRange?.includes(day) ?? false,
                isPredictedFertile:
                    prediction.fertileWindow?.includes(day) ?? false,
                onTap: () => onDayTap(day),
              ),
          ],
        ),
      ],
    );
  }

  /// Full weeks (7-day rows) covering [month], Monday-first, including
  /// enough adjacent-month days to complete the first and last week.
  ///
  /// Builds each day via the `DateTime(year, month, day)` constructor
  /// rather than `DateTime.add(Duration(days: ...))` — adding a Duration
  /// to a local (non-UTC) DateTime walks wall-clock time, so a grid
  /// spanning a DST transition would drift off midnight from that day
  /// onward (see `dateOnly`'s doc in cycle_math.dart for the same
  /// footgun). Passing an out-of-range day to the constructor instead
  /// lets Dart normalize the calendar date directly, which is DST-safe.
  List<DateTime> _daysGrid(DateTime month) {
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final lastOfMonth = DateTime(month.year, month.month + 1, 0);
    final leading = firstOfMonth.weekday - DateTime.monday;
    final daysInGrid = leading + lastOfMonth.day;
    final trailing = (7 - (daysInGrid % 7)) % 7;
    final totalDays = daysInGrid + trailing;

    return [
      for (var i = 0; i < totalDays; i++)
        DateTime(month.year, month.month, 1 - leading + i),
    ];
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
