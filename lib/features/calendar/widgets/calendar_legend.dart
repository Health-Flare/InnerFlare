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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
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
          ],
        ),
        const SizedBox(height: 4),
        // Sources for the estimates above (docs/features/citations.feature).
        // Given its own row (not an inline icon in the legend above) so it
        // reads as a clear, tappable affordance rather than decoration.
        Align(
          alignment: Alignment.centerLeft,
          child: Tooltip(
            message: 'How estimates work',
            child: TextButton.icon(
              onPressed: () => HowEstimatesWorkScreen.open(context),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.deepTeal.withValues(alpha: 0.7),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              icon: const Icon(Icons.info_outline_rounded, size: 16),
              label: Text(
                'How estimates work',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
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
