import 'package:flutter/material.dart';
import 'package:inner_flare/core/theme/app_theme.dart';
import 'package:inner_flare/models/cycle_day_log.dart';
import 'package:inner_flare/models/period_flow.dart';

/// A single day in the calendar month grid.
///
/// Actual logged data always takes visual priority over a prediction — a
/// day that's both logged and inside a predicted range only shows the
/// logged state, so the estimate never looks like it overrides real data.
class CalendarDayCell extends StatelessWidget {
  const CalendarDayCell({
    super.key,
    required this.date,
    required this.log,
    required this.isCurrentMonth,
    required this.isToday,
    required this.isPredictedPeriod,
    required this.isPredictedFertile,
    required this.onTap,
  });

  final DateTime date;
  final CycleDayLog? log;
  final bool isCurrentMonth;
  final bool isToday;
  final bool isPredictedPeriod;
  final bool isPredictedFertile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final flow = log?.periodFlow;
    final hasSymptoms = log?.symptoms.isNotEmpty ?? false;

    Color? fillColor;
    Border? border;
    if (flow != null) {
      fillColor = _colorForFlow(flow);
    } else if (isPredictedPeriod) {
      border = Border.all(color: AppColors.emberOrange, width: 2);
    } else if (isPredictedFertile) {
      border = Border.all(color: AppColors.midTeal, width: 2);
    }

    final textColor = fillColor != null
        ? Colors.white
        : isCurrentMonth
        ? AppColors.deepTeal
        : AppColors.deepTeal.withValues(alpha: 0.35);

    return Tooltip(
      message: _semanticLabel(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              key: ValueKey(date),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: fillColor,
                border:
                    border ??
                    (isToday
                        ? Border.all(color: AppColors.deepTeal, width: 1.5)
                        : null),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (hasSymptoms)
                    Positioned(
                      bottom: 4,
                      child: Icon(
                        Icons.circle,
                        size: 5,
                        color: fillColor != null
                            ? Colors.white
                            : AppColors.midTeal,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _colorForFlow(PeriodFlow flow) {
    switch (flow) {
      case PeriodFlow.spotting:
        return AppColors.softOrange.withValues(alpha: 0.55);
      case PeriodFlow.light:
        return AppColors.softOrange;
      case PeriodFlow.medium:
        return AppColors.emberOrange.withValues(alpha: 0.8);
      case PeriodFlow.heavy:
        return AppColors.emberOrange;
    }
  }

  String _semanticLabel() {
    final dateLabel = '${date.month}/${date.day}';
    final flow = log?.periodFlow;
    if (flow != null) {
      return '$dateLabel — period day (${_flowLabel(flow)})';
    }
    if (log?.symptoms.isNotEmpty ?? false) {
      return '$dateLabel — symptoms logged';
    }
    if (isPredictedPeriod) {
      return '$dateLabel — predicted period (estimate)';
    }
    if (isPredictedFertile) {
      return '$dateLabel — predicted fertile window (estimate)';
    }
    return dateLabel;
  }

  String _flowLabel(PeriodFlow flow) {
    switch (flow) {
      case PeriodFlow.spotting:
        return 'spotting';
      case PeriodFlow.light:
        return 'light';
      case PeriodFlow.medium:
        return 'medium';
      case PeriodFlow.heavy:
        return 'heavy';
    }
  }
}
