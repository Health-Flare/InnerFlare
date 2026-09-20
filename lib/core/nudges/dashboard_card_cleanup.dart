/// Pure trigger conditions for the dashboard cleanup nudge
/// (docs/features/dashboard_visualizations.feature, "The dashboard
/// nudges toward cleanup once there are 6 or more cards" / "A cleanup
/// nudge calls out duplicate cards by name"). The nudge's own
/// dismiss/snooze behavior once triggered is generic — see
/// lib/core/nudges/nudge_rules.dart — this file only decides *when* the
/// cleanup nudge applies and *what* it should say.
library;

import 'package:inner_flare/models/dashboard_card.dart';

/// How many cards (default or added) trigger the cleanup nudge. Set
/// above the 4-card default grid (both quick stats, Calendar, Insights)
/// so the nudge only fires once the user has actually added cards of
/// their own, not just for sitting at the starting layout.
const int cleanupNudgeCardThreshold = 6;

/// Whether [cards] has enough of them to warrant a cleanup nudge.
bool hasEnoughCardsForCleanupNudge(
  List<DashboardCardInstance> cards, {
  int threshold = cleanupNudgeCardThreshold,
}) {
  return cards.length >= threshold;
}

/// Groups of 2+ cards configured identically — same kind, and for
/// gauge/trend cards, the same mode/metric (chart type doesn't count:
/// the same metric shown as a bar and a line is still the same
/// underlying data point twice). Quick stat, Calendar, and Insights
/// cards are fixed defaults and can never appear here. Empty when there
/// are no duplicates.
List<List<DashboardCardInstance>> findDuplicateCardGroups(
  List<DashboardCardInstance> cards,
) {
  final groups = <String, List<DashboardCardInstance>>{};
  for (final card in cards) {
    final key = switch (card.kind) {
      DashboardCardKind.gauge => 'gauge:${card.gaugeMode.name}',
      DashboardCardKind.trend => 'trend:${card.trendMetric.name}',
      DashboardCardKind.quickStat ||
      DashboardCardKind.calendar ||
      DashboardCardKind.insights => null,
    };
    if (key == null) continue;
    (groups[key] ??= []).add(card);
  }
  return [
    for (final group in groups.values)
      if (group.length > 1) group,
  ];
}
