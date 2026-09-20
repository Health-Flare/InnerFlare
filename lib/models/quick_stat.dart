/// One of the two customizable stat types a quick stat card can show
/// (docs/features/quick_stats.feature). Quick stat cards are
/// [DashboardCardInstance]s (lib/models/dashboard_card.dart) like every
/// other card now; these enums are just the values their config carries.
enum QuickStatType {
  daysSinceLastPeriod,
  estimatedDaysToNextPeriod;

  String get label => switch (this) {
    QuickStatType.daysSinceLastPeriod => 'Days since last period',
    QuickStatType.estimatedDaysToNextPeriod => 'Est. days to next period',
  };
}

/// Which point in the last period [QuickStatType.daysSinceLastPeriod]
/// counts from. Meaningless for [QuickStatType.estimatedDaysToNextPeriod],
/// which always anchors to the last period's start date.
enum QuickStatReferencePoint {
  periodStart,
  periodEnd;

  String get label => switch (this) {
    QuickStatReferencePoint.periodStart => 'since it started',
    QuickStatReferencePoint.periodEnd => 'since it ended',
  };
}
