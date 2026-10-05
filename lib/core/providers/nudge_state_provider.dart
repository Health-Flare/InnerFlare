import 'package:inner_flare/core/nudges/dashboard_nudges.dart';
import 'package:inner_flare/core/nudges/nudge_rules.dart';
import 'package:inner_flare/core/providers/cycle_insights_provider.dart';
import 'package:inner_flare/core/providers/dashboard_card_preferences_provider.dart';
import 'package:inner_flare/core/providers/now_provider.dart';
import 'package:inner_flare/core/providers/nudge_state_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'nudge_state_provider.g.dart';

/// The user's stored dismiss/snooze choice for each dashboard nudge, and
/// the actions that change them (docs/features/dashboard_nudges.feature).
/// Choices for nudge ids this app version doesn't know are ignored.
@riverpod
class NudgeStates extends _$NudgeStates {
  @override
  Future<Map<DashboardNudge, NudgeState>> build() async {
    final repository = await ref.watch(nudgeStateRepositoryProvider.future);
    final stored = await repository.getAll();
    final result = <DashboardNudge, NudgeState>{};
    for (final entry in stored.entries) {
      final nudge = DashboardNudge.fromStorageKey(entry.key);
      if (nudge != null) result[nudge] = entry.value;
    }
    return result;
  }

  /// "Don't suggest this again".
  Future<void> dismiss(DashboardNudge nudge) => _save(
    nudge,
    const NudgeState(disposition: NudgeDisposition.dismissedPermanently),
  );

  /// "Not now": about two cycles for a suggestion, until the next card is
  /// added for cleanup.
  Future<void> snooze(DashboardNudge nudge) async {
    final insights = await ref.read(cycleInsightsProvider.future);
    await _save(
      nudge,
      snoozeStateFor(
        nudge,
        now: ref.read(nowProvider)(),
        averageCycleLength: insights.averageCycleLength,
      ),
    );
  }

  /// Called after the user adds a card, from anywhere.
  Future<void> cardAdded() async {
    final repository = await ref.read(nudgeStateRepositoryProvider.future);
    await repository.endCardAddedSnoozes();
    ref.invalidateSelf();
  }

  /// Debug only.
  Future<void> endAllSnoozes() async {
    final repository = await ref.read(nudgeStateRepositoryProvider.future);
    await repository.endAllSnoozes();
    ref.invalidateSelf();
  }

  /// Debug only.
  Future<void> resetAll() async {
    final repository = await ref.read(nudgeStateRepositoryProvider.future);
    await repository.deleteAll();
    ref.invalidateSelf();
  }

  Future<void> _save(DashboardNudge nudge, NudgeState value) async {
    final current = await future;
    state = AsyncData({...current, nudge: value});
    final repository = await ref.read(nudgeStateRepositoryProvider.future);
    await repository.save(nudge.storageKey, value);
  }
}

/// The one dashboard nudge to show now, or null. Recomputes when the card
/// layout, the log, or a stored choice changes.
@riverpod
Future<DashboardNudge?> currentDashboardNudge(Ref ref) async {
  final cards = await ref.watch(dashboardCardPreferencesProvider.future);
  final insights = await ref.watch(cycleInsightsProvider.future);
  final states = await ref.watch(nudgeStatesProvider.future);
  return nudgeToShow(
    inputs: DashboardNudgeInputs(
      cards: cards,
      periodStartCount: insights.periodStartsLogged,
    ),
    states: states,
    now: ref.watch(nowProvider)(),
  );
}
