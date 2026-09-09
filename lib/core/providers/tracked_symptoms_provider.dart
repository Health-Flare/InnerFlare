import 'package:inner_flare/core/providers/tracked_symptoms_repository_provider.dart';
import 'package:inner_flare/models/tracked_symptom.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tracked_symptoms_provider.g.dart';

/// The user's full symptom catalog — built-in defaults plus anything
/// they've added — and each one's enabled state
/// (docs/features/symptom_settings.feature). Backs both the log screen's
/// chip list and the symptom settings screen.
@riverpod
class TrackedSymptomsNotifier extends _$TrackedSymptomsNotifier {
  @override
  Future<List<TrackedSymptom>> build() async {
    final repository = await ref.watch(
      trackedSymptomsRepositoryProvider.future,
    );
    return repository.getAll();
  }

  /// Adds a new custom symptom, enabled by default.
  Future<void> add(String label) async {
    final repository = await ref.read(
      trackedSymptomsRepositoryProvider.future,
    );
    final added = await repository.add(label);
    final current = await future;
    state = AsyncData([...current, added]);
  }

  /// Renames [id]'s label — works for both built-in and custom symptoms.
  Future<void> rename(String id, String label) async {
    final current = await future;
    final index = current.indexWhere((symptom) => symptom.id == id);
    if (index == -1) return;

    final updated = [...current];
    updated[index] = updated[index].copyWith(label: label);
    state = AsyncData(updated);

    final repository = await ref.read(
      trackedSymptomsRepositoryProvider.future,
    );
    await repository.rename(id, label);
  }

  /// Flips whether [id] is offered on the log screen. Never touches any
  /// day already logged with it.
  Future<void> setEnabled(String id, bool enabled) async {
    final current = await future;
    final index = current.indexWhere((symptom) => symptom.id == id);
    if (index == -1) return;

    final updated = [...current];
    updated[index] = updated[index].copyWith(enabled: enabled);
    state = AsyncData(updated);

    final repository = await ref.read(
      trackedSymptomsRepositoryProvider.future,
    );
    await repository.setEnabled(id, enabled);
  }
}
