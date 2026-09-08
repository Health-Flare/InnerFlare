import 'package:flutter/material.dart';
import 'package:inner_flare/core/theme/app_theme.dart';

/// An honest empty-state preview of a future dashboard card. Says plainly
/// that there's nothing to show yet rather than faking data, matching the
/// "no fabricated estimate" rule in docs/features/insights.feature.
class DataPreviewCard extends StatelessWidget {
  const DataPreviewCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.softOrange.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.emberOrange),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.deepTeal.withValues(alpha: 0.7),
              height: 1.4,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: card,
    );
  }
}
