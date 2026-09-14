/// One of the two customizable stat types shown in the dashboard's quick
/// stats row (docs/features/quick_stats.feature).
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

/// One quick stat slot's configuration, as stored per-device. There are
/// exactly two slots (0 and 1), rendered in slot order.
class QuickStatPreference {
  const QuickStatPreference({
    required this.slot,
    required this.type,
    this.referencePoint = QuickStatReferencePoint.periodEnd,
  });

  final int slot;
  final QuickStatType type;
  final QuickStatReferencePoint referencePoint;

  QuickStatPreference copyWith({
    QuickStatType? type,
    QuickStatReferencePoint? referencePoint,
  }) {
    return QuickStatPreference(
      slot: slot,
      type: type ?? this.type,
      referencePoint: referencePoint ?? this.referencePoint,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is QuickStatPreference &&
        other.slot == slot &&
        other.type == type &&
        other.referencePoint == referencePoint;
  }

  @override
  int get hashCode => Object.hash(slot, type, referencePoint);
}
