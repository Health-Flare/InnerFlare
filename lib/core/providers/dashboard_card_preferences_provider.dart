import 'package:inner_flare/core/providers/dashboard_card_preferences_repository_provider.dart';
import 'package:inner_flare/models/dashboard_card.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dashboard_card_preferences_provider.g.dart';

/// The dashboard's customizable card layout — show/hide and order
/// (docs/features/dashboard.feature). Backs both the dashboard screen's
/// rendering and the customization screen's controls.
@riverpod
class DashboardCardPreferencesNotifier
    extends _$DashboardCardPreferencesNotifier {
  @override
  Future<List<DashboardCardPreference>> build() async {
    final repository = await ref.watch(
      dashboardCardPreferencesRepositoryProvider.future,
    );
    return repository.getAll();
  }

  /// Flips [card]'s visibility. Hiding keeps its position so re-hiding and
  /// re-showing without a manual reorder in between is a no-op on order;
  /// showing moves it to the end of the current order (see "Re-showing a
  /// previously hidden card").
  Future<void> toggleVisibility(DashboardCard card) async {
    final current = await future;
    final index = current.indexWhere((pref) => pref.card == card);
    if (index == -1) return;
    final pref = current[index];

    final updated = [...current];
    if (pref.visible) {
      updated[index] = pref.copyWith(visible: false);
    } else {
      updated
        ..removeAt(index)
        ..add(pref.copyWith(visible: true));
    }
    await _persist(updated);
  }

  /// Moves the card at [oldIndex] to [newIndex] in the full (visible +
  /// hidden) list, matching `ReorderableListView`'s index semantics.
  Future<void> reorder(int oldIndex, int newIndex) async {
    final current = await future;
    final updated = [...current];
    final moved = updated.removeAt(oldIndex);
    final insertAt = newIndex > oldIndex ? newIndex - 1 : newIndex;
    updated.insert(insertAt, moved);
    await _persist(updated);
  }

  Future<void> _persist(List<DashboardCardPreference> prefs) async {
    final withOrders = [
      for (var i = 0; i < prefs.length; i++) prefs[i].copyWith(order: i),
    ];
    state = AsyncData(withOrders);
    final repository = await ref.read(
      dashboardCardPreferencesRepositoryProvider.future,
    );
    await repository.saveAll(withOrders);
  }
}
