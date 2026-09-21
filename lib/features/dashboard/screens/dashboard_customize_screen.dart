import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inner_flare/core/providers/dashboard_card_preferences_provider.dart';
import 'package:inner_flare/features/dashboard/screens/add_dashboard_card_screen.dart';
import 'package:inner_flare/features/dashboard/widgets/dashboard_card_grid.dart';
import 'package:inner_flare/features/dashboard/widgets/dashboard_chip.dart';
import 'package:inner_flare/models/dashboard_card.dart';
import 'package:inner_flare/models/quick_stat.dart';

/// Lets the user show, hide, reorder, and (for gauge/trend cards) add,
/// remove, and reconfigure dashboard cards (docs/features/dashboard.
/// feature, docs/features/dashboard_visualizations.feature). Calendar and
/// Insights can always be hidden but never removed outright. Every other
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

  /// Renders a card for the resize preview grid: a lightweight,
  /// data-independent stand-in for the real card (which the dashboard
  /// itself renders from the user's actual logged history). This is a
  /// sizing preview, not a place to read real values, so it never touches
  /// the cycle-data providers the real cards do.
  static Widget _buildPreviewCard(DashboardCardInstance instance) {
    switch (instance.kind) {
      case DashboardCardKind.quickStat:
        return DashboardChip(
          icon: Icons.numbers_rounded,
          title: instance.quickStatType.label,
        );
      case DashboardCardKind.calendar:
        return const DashboardChip(
          icon: Icons.calendar_month_rounded,
          title: 'Calendar',
        );
      case DashboardCardKind.insights:
        return const DashboardChip(
          icon: Icons.insights_rounded,
          title: 'Insights',
        );
      case DashboardCardKind.gauge:
        return DashboardChip(
          icon: Icons.speed_rounded,
          title: instance.gaugeMode.label,
        );
      case DashboardCardKind.trend:
        return DashboardChip(
          icon: Icons.show_chart_rounded,
          title: instance.trendMetric.label,
        );
    }
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
          final visibleCards = prefs
              .where((instance) => instance.visible)
              .toList();
          // Built from CustomScrollView + SliverReorderableList directly
          // (the documented way to combine a reorderable list with other
          // content in one scroll view, see [SliverReorderableList])
          // rather than ReorderableListView.builder's own `header:`
          // support: that support's header/footer padding-splitting logic
          // was observed corrupting the list's item count across separate
          // `testWidgets` runs in the same test file once the header held
          // more than trivial content, which this sidesteps entirely.
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Text(
                        'This is your dashboard to shape. Turn any card '
                        'off, drag to reorder, or add a gauge or trend '
                        'card from your own data.',
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: Text(
                        visibleCards.isEmpty
                            ? 'Show a card to resize it here.'
                            : "Drag a card's corner to resize it: the "
                                  'dashboard reflows to match.',
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: DashboardCardGrid(
                        instances: visibleCards,
                        cardBuilder: _buildPreviewCard,
                        resizable: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                sliver: SliverReorderableList(
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
      DashboardCardKind.quickStat => instance.quickStatType.label,
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
        if (instance.kind == DashboardCardKind.quickStat)
          _QuickStatSelector(instance: instance),
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

class _QuickStatSelector extends ConsumerWidget {
  const _QuickStatSelector({required this.instance});

  final DashboardCardInstance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(dashboardCardPreferencesProvider.notifier);
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Column(
        children: [
          RadioGroup<QuickStatType>(
            groupValue: instance.quickStatType,
            onChanged: (type) {
              if (type == null) return;
              notifier.updateConfig(
                instance.id,
                DashboardCardConfigKeys.quickStatType,
                type.name,
              );
            },
            child: Column(
              children: [
                for (final type in QuickStatType.values)
                  RadioListTile<QuickStatType>(
                    key: ValueKey('${instance.id}-type-${type.name}'),
                    title: Text(type.label),
                    value: type,
                  ),
              ],
            ),
          ),
          if (instance.quickStatType == QuickStatType.daysSinceLastPeriod)
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: RadioGroup<QuickStatReferencePoint>(
                groupValue: instance.quickStatReferencePoint,
                onChanged: (point) {
                  if (point == null) return;
                  notifier.updateConfig(
                    instance.id,
                    DashboardCardConfigKeys.quickStatReferencePoint,
                    point.name,
                  );
                },
                child: Column(
                  children: [
                    for (final point in QuickStatReferencePoint.values)
                      RadioListTile<QuickStatReferencePoint>(
                        key: ValueKey('${instance.id}-refpoint-${point.name}'),
                        title: Text(point.label),
                        value: point,
                      ),
                  ],
                ),
              ),
            ),
        ],
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
