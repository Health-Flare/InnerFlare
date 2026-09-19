import 'package:inner_flare/core/providers/dashboard_card_preferences_repository_provider.dart';
import 'package:inner_flare/models/dashboard_card.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dashboard_card_preferences_provider.g.dart';

/// The dashboard's customizable card layout — show/hide, order, add/remove,
/// and per-card mode config (docs/features/dashboard.feature,
/// docs/features/dashboard_visualizations.feature). Backs both the
/// dashboard screen's rendering and the customization/add-card screens'
/// controls. Every mutator here is keyed off [DashboardCardInstance.id],
/// never [DashboardCardKind], since more than one instance of the same
/// kind can exist.
@riverpod
class DashboardCardPreferencesNotifier
    extends _$DashboardCardPreferencesNotifier {
  @override
  Future<List<DashboardCardInstance>> build() async {
    final repository = await ref.watch(
      dashboardCardPreferencesRepositoryProvider.future,
    );
    return repository.getAll();
  }

  /// Flips the instance identified by [id]'s visibility. Hiding keeps its
  /// position so re-hiding and re-showing without a manual reorder in
  /// between is a no-op on order; showing moves it to the end of the
  /// current order (see "Re-showing a previously hidden card").
  Future<void> toggleVisibility(String id) async {
    final current = await future;
    final index = current.indexWhere((instance) => instance.id == id);
    if (index == -1) return;
    final instance = current[index];

    final updated = [...current];
    if (instance.visible) {
      updated[index] = instance.copyWith(visible: false);
    } else {
      updated
        ..removeAt(index)
        ..add(instance.copyWith(visible: true));
    }
    await _persist(updated);
  }

  /// Moves the card at [oldIndex] to [newIndex] in the full (visible +
  /// hidden) list, matching `ReorderableListView.onReorderItem`'s index
  /// semantics: [newIndex] is already adjusted for the removed item at
  /// [oldIndex].
  Future<void> reorder(int oldIndex, int newIndex) async {
    final current = await future;
    final updated = [...current];
    final moved = updated.removeAt(oldIndex);
    updated.insert(newIndex, moved);
    await _persist(updated);
  }

  /// Appends a newly-added gauge/trend card (see
  /// `newGaugeCardInstance`/`newTrendCardInstance` in
  /// lib/models/dashboard_card.dart), visible immediately at the end of
  /// the current order.
  Future<void> addCard(DashboardCardInstance instance) async {
    final current = await future;
    await _persist([...current, instance]);
  }

  /// Removes the instance identified by [id] entirely — for gauge/trend
  /// cards the user added, as opposed to hiding a default card. No-op for
  /// an id that isn't found (already removed).
  Future<void> removeCard(String id) async {
    final current = await future;
    await _persist(current.where((instance) => instance.id != id).toList());
  }

  /// Updates one config value on the instance identified by [id] — e.g.
  /// switching a gauge's mode or a trend card's chart type (see "Switching
  /// a gauge card between its two supported modes", "A trend card can be
  /// switched from bar to line").
  Future<void> updateConfig(String id, String key, String value) async {
    final current = await future;
    final index = current.indexWhere((instance) => instance.id == id);
    if (index == -1) return;

    final updated = [...current];
    updated[index] = updated[index].withConfigValue(key, value);
    await _persist(updated);
  }

  Future<void> _persist(List<DashboardCardInstance> instances) async {
    final withOrders = [
      for (var i = 0; i < instances.length; i++)
        instances[i].copyWith(order: i),
    ];
    state = AsyncData(withOrders);
    final repository = await ref.read(
      dashboardCardPreferencesRepositoryProvider.future,
    );
    await repository.saveAll(withOrders);
  }
}
