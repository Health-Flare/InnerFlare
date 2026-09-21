import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inner_flare/core/providers/dashboard_visualization_displays_provider.dart';
import 'package:inner_flare/features/dashboard/widgets/dashboard_chip.dart';
import 'package:inner_flare/models/dashboard_card.dart';
import 'package:inner_flare/models/quick_stat.dart';

/// A quick stat card (docs/features/quick_stats.feature), one of the
/// grid's fixed default cells, alongside Calendar and Insights (docs/
/// features/dashboard_grid_layout.feature).
class QuickStatChip extends ConsumerWidget {
  const QuickStatChip({super.key, required this.instance});

  final DashboardCardInstance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayAsync = ref.watch(quickStatCardDisplayProvider(instance));

    return displayAsync.when(
      loading: () =>
          DashboardChip(title: instance.quickStatType.label, value: '…'),
      error: (error, _) =>
          DashboardChip(title: instance.quickStatType.label, value: '—'),
      data: (display) {
        final value = display.value;
        final isEstimate =
            display.type == QuickStatType.estimatedDaysToNextPeriod;
        final valueText = value == null
            ? 'Not enough data yet'
            : (isEstimate && value < 0 ? '${-value} days overdue' : '$value');
        final subtitle = isEstimate
            ? 'an estimate'
            : display.referencePoint.label;

        return DashboardChip(
          title: display.type.label,
          value: valueText,
          valueIsProminent: value != null,
          subtitle: subtitle,
        );
      },
    );
  }
}
