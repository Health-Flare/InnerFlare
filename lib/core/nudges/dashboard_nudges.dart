/// Which dashboard nudge, if any, to show right now (#44,
/// docs/features/dashboard_nudges.feature and the nudge scenarios in
/// docs/features/dashboard_visualizations.feature). Pure: no Flutter, no
/// database, "now" passed in, matching nudge_rules.dart.
///
/// Builds on two existing pieces:
/// - nudge_rules.dart: whether one nudge shows, given its stored state
/// - dashboard_card_cleanup.dart: duplicate-card detection
library;

import 'package:inner_flare/core/nudges/dashboard_card_cleanup.dart';
import 'package:inner_flare/core/nudges/nudge_rules.dart';
import 'package:inner_flare/models/dashboard_card.dart';

/// Every dashboard nudge, in priority order: when more than one applies,
/// the first one that isn't dismissed or snoozed is shown, and only that
/// one ("Only one nudge shows at a time").
enum DashboardNudge {
  /// Too many cards showing, or duplicates. One nudge with two wordings,
  /// so dismissing it quiets both.
  cleanup('dashboard_cleanup'),

  /// "You've logged a period: a gauge card can show where you are."
  suggestGauge('suggest_gauge_card'),

  /// "You have 2+ cycles: a trend chart can show how they compare."
  suggestTrend('suggest_trend_card');

  const DashboardNudge(this.storageKey);

  /// Stored in `nudge_states.nudge_id`. Never derived from the enum name,
  /// so renaming a value in code can't orphan the user's saved choice.
  final String storageKey;

  /// Card suggestions snooze for about two cycles; cleanup snoozes until
  /// the next card is added (dashboard_nudges.feature).
  bool get isSuggestion => this != DashboardNudge.cleanup;

  static DashboardNudge? fromStorageKey(String key) {
    for (final nudge in values) {
      if (nudge.storageKey == key) return nudge;
    }
    return null;
  }
}

/// Visible cards needed for the general cleanup nudge. 7, not the
/// earlier 6: the default layout is 4 cards and accepting both card
/// suggestions makes 6, so 6 would nag right after the app's own advice
/// (see dashboard_visualizations.feature). Duplicates trigger it at any
/// count.
const int cleanupNudgeVisibleCardThreshold = 7;

/// Period starts needed before suggesting a trend card: 3 starts make 2
/// complete cycles, the same bar that makes a trend card tappable.
const int _trendSuggestionPeriodStarts = 3;

/// Everything nudge selection reads, gathered by the provider layer.
class DashboardNudgeInputs {
  const DashboardNudgeInputs({
    required this.cards,
    required this.periodStartCount,
  });

  /// Every card instance, shown and hidden.
  final List<DashboardCardInstance> cards;

  /// How many period starts the log has.
  final int periodStartCount;

  List<DashboardCardInstance> get visibleCards =>
      cards.where((c) => c.visible).toList();
}

/// Every nudge whose trigger currently holds, in priority order, before
/// any dismiss/snooze state is applied.
List<DashboardNudge> applicableNudges(DashboardNudgeInputs inputs) {
  final visible = inputs.visibleCards;
  final hasGauge = inputs.cards.any((c) => c.kind == DashboardCardKind.gauge);
  final hasCycleLengthTrend = inputs.cards.any(
    (c) =>
        c.kind == DashboardCardKind.trend &&
        c.trendMetric == TrendCardMetric.previousCycleLengths,
  );

  return [
    if (visible.length >= cleanupNudgeVisibleCardThreshold ||
        findDuplicateCardGroups(visible).isNotEmpty)
      DashboardNudge.cleanup,
    if (!hasGauge && inputs.periodStartCount >= 1) DashboardNudge.suggestGauge,
    if (!hasCycleLengthTrend &&
        inputs.periodStartCount >= _trendSuggestionPeriodStarts)
      DashboardNudge.suggestTrend,
  ];
}

/// The one nudge to show now, or null. [states] holds the stored choice
/// for each nudge the user has acted on.
DashboardNudge? nudgeToShow({
  required DashboardNudgeInputs inputs,
  required Map<DashboardNudge, NudgeState> states,
  required DateTime now,
}) {
  for (final nudge in applicableNudges(inputs)) {
    if (shouldShowNudge(state: states[nudge], now: now)) return nudge;
  }
  return null;
}

/// The state to store when the user taps "Not now" on [nudge].
NudgeState snoozeStateFor(
  DashboardNudge nudge, {
  required DateTime now,
  required double? averageCycleLength,
}) {
  if (!nudge.isSuggestion) {
    return const NudgeState(
      disposition: NudgeDisposition.snoozedUntilCardAdded,
    );
  }
  return NudgeState(
    disposition: NudgeDisposition.snoozed,
    snoozedUntil: suggestionNudgeSnoozeUntil(
      now: now,
      averageCycleLength: averageCycleLength,
    ),
  );
}

/// Ids of the visible cards "Remove extra" deletes: every card in a
/// duplicate group except the first, which stays where it is.
List<String> extraDuplicateCardIds(List<DashboardCardInstance> cards) {
  final visible = cards.where((c) => c.visible).toList();
  return [
    for (final group in findDuplicateCardGroups(visible))
      for (final extra in group.skip(1)) extra.id,
  ];
}
