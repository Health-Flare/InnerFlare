import 'package:flutter/material.dart';
import 'package:inner_flare/core/theme/app_theme.dart';
import 'package:inner_flare/features/insights/screens/how_estimates_work_screen.dart';

/// Explains what each calendar marking means: predictions are explicitly
/// labeled as estimates, never confirmed events
/// (docs/features/calendar.feature).
class CalendarLegend extends StatelessWidget {
  const CalendarLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _swatch(context, color: AppColors.emberOrange, label: 'Period'),
        _swatch(
          context,
          color: AppColors.midTeal,
          label: 'Symptoms',
          isDot: true,
        ),
        _swatch(
          context,
          color: AppColors.emberOrange,
          label: 'Predicted period (estimate)',
          isRing: true,
        ),
        _swatch(
          context,
          color: AppColors.midTeal,
          label: 'Fertile window (estimate)',
          isRing: true,
        ),
        // Sources for the estimates above (docs/features/citations.feature).
        SizedBox(
          height: 14,
          child: IconButton(
            tooltip: 'How estimates work',
            padding: EdgeInsets.zero,
            iconSize: 16,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 14),
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () => HowEstimatesWorkScreen.open(context),
          ),
        ),
      ],
    );
  }

  Widget _swatch(
    BuildContext context, {
    required Color color,
    required String label,
    bool isDot = false,
    bool isRing = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 14,
          height: 14,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isRing ? null : (isDot ? Colors.transparent : color),
              border: isRing ? Border.all(color: color, width: 2) : null,
            ),
            child: isDot ? Icon(Icons.circle, size: 6, color: color) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.deepTeal.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
