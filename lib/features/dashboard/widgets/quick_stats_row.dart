import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inner_flare/core/providers/quick_stat_displays_provider.dart';
import 'package:inner_flare/core/theme/app_theme.dart';
import 'package:inner_flare/models/quick_stat.dart';

/// The two customizable at-a-glance numbers between the "log today" hero
/// card and "Your data, at a glance" (docs/features/quick_stats.feature).
class QuickStatsRow extends ConsumerWidget {
  const QuickStatsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displaysAsync = ref.watch(quickStatDisplaysProvider);
    final displays = displaysAsync.value ?? const <QuickStatDisplay>[];
    if (displays.isEmpty) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < displays.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(child: _QuickStatTile(display: displays[i])),
        ],
      ],
    );
  }
}

class _QuickStatTile extends StatelessWidget {
  const _QuickStatTile({required this.display});

  final QuickStatDisplay display;

  @override
  Widget build(BuildContext context) {
    final value = display.value;
    final isEstimate = display.type == QuickStatType.estimatedDaysToNextPeriod;
    final valueText = value == null
        ? 'Not enough data yet'
        : (isEstimate && value < 0 ? '${-value} days overdue' : '$value');
    final subtitle = isEstimate ? 'an estimate' : display.referencePoint.label;

    return Container(
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
          Text(
            display.type.label,
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 6),
          Text(
            valueText,
            style: value == null
                ? Theme.of(context).textTheme.titleMedium
                : Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
