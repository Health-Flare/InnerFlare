import 'package:flutter/material.dart';
import 'package:inner_flare/core/theme/app_theme.dart';

/// A single-grid-cell tile shared by quick stat, Calendar, and Insights
/// cards (docs/features/dashboard_grid_layout.feature) — the same
/// container and text treatment for all three, so none reads as more or
/// less important than another. Exactly one of [icon] or [value] is
/// expected: quick stats show a number ([value]); Calendar and Insights
/// show an [icon] instead, since neither has a single number to lead
/// with.
class DashboardChip extends StatelessWidget {
  const DashboardChip({
    super.key,
    required this.title,
    this.icon,
    this.value,
    this.valueIsProminent = true,
    this.subtitle,
    this.onTap,
  }) : assert(
         (icon == null) != (value == null),
         'DashboardChip takes exactly one of icon or value',
       );

  final String title;
  final IconData? icon;
  final String? value;

  /// False for a value that's really a message ("Not enough data yet")
  /// rather than a number — rendered smaller so a longer line of text
  /// doesn't look absurd at the normal bold/headline size.
  final bool valueIsProminent;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.emberOrange.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.softOrange.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.emberOrange, size: 20),
            )
          else
            Text(
              value!,
              style: valueIsProminent
                  ? Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    )
                  : Theme.of(context).textTheme.titleMedium,
            ),
          const SizedBox(height: 8),
          Text(title, style: Theme.of(context).textTheme.labelMedium),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return chip;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: chip,
    );
  }
}
