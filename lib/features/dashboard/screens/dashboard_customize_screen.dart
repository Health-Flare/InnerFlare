import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inner_flare/core/providers/dashboard_card_preferences_provider.dart';
import 'package:inner_flare/features/dashboard/screens/add_dashboard_card_screen.dart';
import 'package:inner_flare/models/dashboard_card.dart';

/// Lets the user show, hide, reorder, and (for gauge/trend cards) add,
/// remove, and reconfigure dashboard cards (docs/features/dashboard.
/// feature, docs/features/dashboard_visualizations.feature). Calendar and
/// Insights can always be hidden but never removed outright — every other
/// card here was explicitly added via [AddDashboardCardScreen] and can be
/// removed the same way it was added. The "log today" entry point isn't
/// listed because it isn't a card; it's always on the dashboard regardless
/// of what's customized here.
class DashboardCustomizeScreen extends ConsumerWidget {
  const DashboardCustomizeScreen({super.key});

  void _openAddCard(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AddDashboardCardScreen()));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(dashboardCardPreferencesProvider);
    final notifier = ref.read(dashboardCardPreferencesProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customize dashboard'),
        actions: [
          IconButton(
            tooltip: 'Add a card',
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _openAddCard(context),
          ),
        ],
      ),
      body: prefsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Couldn\'t load: $error')),
        data: (prefs) {
          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'This is your dashboard to shape. Turn any card off, drag '
                  'to reorder, or add a gauge or trend card from your own '
                  'data.',
                ),
              ),
              Expanded(
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: prefs.length,
                  onReorderItem: (oldIndex, newIndex) {
                    notifier.reorder(oldIndex, newIndex);
                  },
                  itemBuilder: (context, index) {
                    final instance = prefs[index];
                    return _CardTile(
                      key: ValueKey(instance.id),
                      index: index,
                      instance: instance,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CardTile extends ConsumerWidget {
  const _CardTile({super.key, required this.index, required this.instance});

  final int index;
  final DashboardCardInstance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(dashboardCardPreferencesProvider.notifier);
    final title = switch (instance.kind) {
      DashboardCardKind.gauge => instance.gaugeMode.label,
      DashboardCardKind.trend => instance.trendMetric.label,
      _ => instance.kind.label,
    };

    return Column(
      key: ValueKey('${instance.id}-column'),
      children: [
        SwitchListTile(
          title: Text(title),
          subtitle: instance.kind.isDefault ? null : Text(instance.kind.label),
          value: instance.visible,
          onChanged: (_) => notifier.toggleVisibility(instance.id),
          secondary: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!instance.kind.isDefault)
                IconButton(
                  tooltip: 'Remove card',
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () => notifier.removeCard(instance.id),
                ),
              ReorderableDragStartListener(
                index: index,
                child: const Icon(Icons.drag_handle_rounded),
              ),
            ],
          ),
        ),
        if (instance.kind == DashboardCardKind.gauge)
          _GaugeModeSelector(instance: instance),
        if (instance.kind == DashboardCardKind.trend)
          _TrendChartTypeSelector(instance: instance),
      ],
    );
  }
}

class _GaugeModeSelector extends ConsumerWidget {
  const _GaugeModeSelector({required this.instance});

  final DashboardCardInstance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(dashboardCardPreferencesProvider.notifier);
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: RadioGroup<GaugeCardMode>(
        groupValue: instance.gaugeMode,
        onChanged: (mode) {
          if (mode == null) return;
          notifier.updateConfig(
            instance.id,
            DashboardCardConfigKeys.gaugeMode,
            mode.name,
          );
        },
        child: Column(
          children: [
            for (final mode in GaugeCardMode.values)
              RadioListTile<GaugeCardMode>(
                key: ValueKey('${instance.id}-mode-${mode.name}'),
                title: Text(mode.label),
                value: mode,
              ),
          ],
        ),
      ),
    );
  }
}

class _TrendChartTypeSelector extends ConsumerWidget {
  const _TrendChartTypeSelector({required this.instance});

  final DashboardCardInstance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(dashboardCardPreferencesProvider.notifier);
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: RadioGroup<TrendChartType>(
        groupValue: instance.trendChartType,
        onChanged: (type) {
          if (type == null) return;
          notifier.updateConfig(
            instance.id,
            DashboardCardConfigKeys.trendChartType,
            type.name,
          );
        },
        child: Column(
          children: [
            for (final type in TrendChartType.values)
              RadioListTile<TrendChartType>(
                key: ValueKey('${instance.id}-charttype-${type.name}'),
                title: Text(type.label),
                value: type,
              ),
          ],
        ),
      ),
    );
  }
}
