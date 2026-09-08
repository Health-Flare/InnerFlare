import 'package:flutter/material.dart';
import 'package:inner_flare/core/theme/app_theme.dart';

/// A single labeled statistic or estimate on the insights screen — an
/// average, a variability figure, or a predicted date range. [caveat], when
/// set, is shown in a muted tone below the value (e.g. "Estimate based on
/// your last 6 cycles" or an irregularity warning) so every number is
/// paired with what it's based on, per the "transparent statistics, not an
/// opaque model" design decision.
class InsightStatCard extends StatelessWidget {
  const InsightStatCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.caveat,
  });

  final IconData icon;
  final String title;
  final String value;
  final String? caveat;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.emberOrange.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.emberOrange, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.deepTeal.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (caveat != null) ...[
            const SizedBox(height: 6),
            Text(
              caveat!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.deepTeal.withValues(alpha: 0.6),
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
