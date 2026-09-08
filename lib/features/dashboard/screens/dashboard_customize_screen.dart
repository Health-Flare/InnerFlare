import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inner_flare/core/providers/dashboard_card_preferences_provider.dart';

/// Lets the user show, hide, and reorder dashboard cards
/// (docs/features/dashboard.feature). Every card here can be hidden —
/// none is mandatory. The "log today" entry point isn't listed because
/// it isn't a card; it's always on the dashboard regardless of what's
/// customized here.
///
/// TODO(dashboard): This covers dashboard.feature (show/hide/reorder) but
/// not dashboard_visualizations.feature yet — there's no "add card" flow,
/// no gauge/trend card types, and no per-card chart-type or gauge-mode
/// switching. [DashboardCard] currently has exactly the two cards that
/// existed before customization landed (calendar, insights); adding a
/// visualization card type means extending that enum, teaching
/// [DashboardCardPreferencesRepository] nothing new (it's already
/// type-agnostic), and giving DashboardScreen._buildCard a case for it.
class DashboardCustomizeScreen extends ConsumerWidget {
  const DashboardCustomizeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(dashboardCardPreferencesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Customize dashboard')),
      body: prefsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Couldn\'t load: $error')),
        data: (prefs) {
          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'This is your dashboard to shape. Turn any card off, or '
                  'drag to reorder the ones you keep.',
                ),
              ),
              Expanded(
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: prefs.length,
                  onReorderItem: (oldIndex, newIndex) {
                    ref
                        .read(dashboardCardPreferencesProvider.notifier)
                        .reorder(oldIndex, newIndex);
                  },
                  itemBuilder: (context, index) {
                    final pref = prefs[index];
                    return SwitchListTile(
                      key: ValueKey(pref.card),
                      title: Text(pref.card.label),
                      value: pref.visible,
                      onChanged: (_) {
                        ref
                            .read(dashboardCardPreferencesProvider.notifier)
                            .toggleVisibility(pref.card);
                      },
                      secondary: ReorderableDragStartListener(
                        index: index,
                        child: const Icon(Icons.drag_handle_rounded),
                      ),
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
