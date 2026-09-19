import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inner_flare/core/providers/dashboard_card_preferences_provider.dart';
import 'package:inner_flare/models/dashboard_card.dart';

/// The "add card" catalog (docs/features/dashboard_visualizations.feature,
/// "Additional data points can be added as their own cards"). Every entry
/// here creates a brand-new [DashboardCardInstance] — adding the same kind
/// twice (e.g. two trend cards for different metrics) is expected and
/// supported, unlike the fixed calendar/insights cards in
/// [DashboardCustomizeScreen].
class AddDashboardCardScreen extends ConsumerWidget {
  const AddDashboardCardScreen({super.key});

  Future<void> _add(
    BuildContext context,
    WidgetRef ref,
    DashboardCardInstance Function(int order) build,
  ) async {
    final current = await ref.read(dashboardCardPreferencesProvider.future);
    await ref
        .read(dashboardCardPreferencesProvider.notifier)
        .addCard(build(current.length));
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add a card')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Text(
              'Every card here reads only from what you\'ve already logged '
              'on this device.',
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Text(
              'Gauge',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          for (final mode in GaugeCardMode.values)
            ListTile(
              key: ValueKey('add-card-gauge-${mode.name}'),
              leading: const Icon(Icons.speed_rounded),
              title: Text(mode.label),
              onTap: () => _add(
                context,
                ref,
                (order) => newGaugeCardInstance(order: order, mode: mode),
              ),
            ),
          const Divider(height: 32),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Text(
              'Trend chart',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          for (final metric in TrendCardMetric.values)
            ListTile(
              key: ValueKey('add-card-trend-${metric.name}'),
              leading: const Icon(Icons.show_chart_rounded),
              title: Text(metric.label),
              subtitle: metric.isImplemented ? null : const Text('Coming soon'),
              enabled: metric.isImplemented,
              onTap: !metric.isImplemented
                  ? null
                  : () => _add(
                      context,
                      ref,
                      (order) =>
                          newTrendCardInstance(order: order, metric: metric),
                    ),
            ),
        ],
      ),
    );
  }
}
