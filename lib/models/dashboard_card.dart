/// A customizable card on the dashboard (docs/features/dashboard.feature).
/// The "log today" entry point is not in this set — it is a persistent
/// part of the dashboard shell, never hidden (see "Hiding every card
/// still leaves the log entry point reachable").
enum DashboardCard {
  calendar,
  insights;

  String get label => switch (this) {
    DashboardCard.calendar => 'Calendar',
    DashboardCard.insights => 'Insights',
  };
}

/// One card's show/hide state and position, as stored per-device.
class DashboardCardPreference {
  const DashboardCardPreference({
    required this.card,
    required this.visible,
    required this.order,
  });

  final DashboardCard card;
  final bool visible;
  final int order;

  DashboardCardPreference copyWith({bool? visible, int? order}) {
    return DashboardCardPreference(
      card: card,
      visible: visible ?? this.visible,
      order: order ?? this.order,
    );
  }
}
