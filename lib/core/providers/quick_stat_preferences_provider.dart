import 'package:inner_flare/core/providers/quick_stat_preferences_repository_provider.dart';
import 'package:inner_flare/models/quick_stat.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'quick_stat_preferences_provider.g.dart';

/// The dashboard's two customizable quick stat slots (docs/features/
/// quick_stats.feature). Backs both the dashboard's display and the
/// customization screen's controls.
@riverpod
class QuickStatPreferencesNotifier extends _$QuickStatPreferencesNotifier {
  @override
  Future<List<QuickStatPreference>> build() async {
    final repository = await ref.watch(
      quickStatPreferencesRepositoryProvider.future,
    );
    return repository.getAll();
  }

  /// Changes [slot]'s stat type, independently of the other slot — both
  /// slots are always allowed to show the same type (see "Quick stats are
  /// individually customizable, not just show or hide").
  Future<void> setType(int slot, QuickStatType type) async {
    await _update(slot, (pref) => pref.copyWith(type: type));
  }

  /// Changes [slot]'s reference point (only meaningful for
  /// [QuickStatType.daysSinceLastPeriod]).
  Future<void> setReferencePoint(
    int slot,
    QuickStatReferencePoint referencePoint,
  ) async {
    await _update(
      slot,
      (pref) => pref.copyWith(referencePoint: referencePoint),
    );
  }

  Future<void> _update(
    int slot,
    QuickStatPreference Function(QuickStatPreference) transform,
  ) async {
    final current = await future;
    final index = current.indexWhere((pref) => pref.slot == slot);
    if (index == -1) return;

    final updated = transform(current[index]);
    final newState = [...current];
    newState[index] = updated;
    state = AsyncData(newState);

    final repository = await ref.read(
      quickStatPreferencesRepositoryProvider.future,
    );
    await repository.save(updated);
  }
}
