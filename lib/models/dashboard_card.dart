/// A customizable card on the dashboard (docs/features/dashboard.feature,
/// docs/features/dashboard_visualizations.feature). The "log today" entry
/// point is not in this set — it is a persistent part of the dashboard
/// shell, never hidden (see "Hiding every card still leaves the log entry
/// point reachable").
enum DashboardCardKind {
  calendar,
  insights,
  gauge,
  trend;

  String get label => switch (this) {
    DashboardCardKind.calendar => 'Calendar',
    DashboardCardKind.insights => 'Insights',
    DashboardCardKind.gauge => 'Gauge',
    DashboardCardKind.trend => 'Trend chart',
  };

  /// Calendar and Insights exist for every user from the start — hidden
  /// with the same show/hide toggle as everything else, but never
  /// "removed" outright, and never something you'd find in the add-card
  /// catalog. Gauge/trend cards are the opposite: nothing appears until
  /// the user explicitly adds one (see "Additional data points can be
  /// added as their own cards"), and each addition is its own removable
  /// [DashboardCardInstance].
  bool get isDefault =>
      this == DashboardCardKind.calendar || this == DashboardCardKind.insights;
}

/// Which value a gauge card displays (docs/features/dashboard_visualizations
/// .feature, "A gauge card can show..."). Both modes fill the gauge
/// relative to the user's own average cycle length, never a fixed scale.
enum GaugeCardMode {
  daysSinceLastPeriod,
  estimatedDaysUntilNextPeriod;

  String get label => switch (this) {
    GaugeCardMode.daysSinceLastPeriod => 'Days since last period',
    GaugeCardMode.estimatedDaysUntilNextPeriod =>
      'Estimated days until next period',
  };
}

/// Which data a trend card plots. Only [previousCycleLengths] has a real
/// data source today — the others are named here so the add-card catalog
/// and per-instance config shape are already in place, but
/// [lib/core/providers/dashboard_visualization_displays_provider.dart]
/// only knows how to compute [previousCycleLengths] so far; see the TODO
/// there before wiring these up (docs/features/dashboard_visualizations
/// .feature, "Additional data points can be added as their own cards").
enum TrendCardMetric {
  previousCycleLengths,
  symptomFrequency,
  flowIntensity,
  cycleLengthVariability;

  String get label => switch (this) {
    TrendCardMetric.previousCycleLengths => 'Previous cycle lengths',
    TrendCardMetric.symptomFrequency => 'Symptom frequency by day of cycle',
    TrendCardMetric.flowIntensity => 'Flow intensity over time',
    TrendCardMetric.cycleLengthVariability => 'Cycle length variability',
  };

  bool get isImplemented => this == TrendCardMetric.previousCycleLengths;
}

/// How a trend card's data is plotted — switchable per-card, per
/// "A trend card can be switched from bar to line".
enum TrendChartType {
  bar,
  line;

  String get label => switch (this) {
    TrendChartType.bar => 'Bar chart',
    TrendChartType.line => 'Line chart',
  };
}

/// Config keys used inside [DashboardCardInstance.config]. The repository
/// treats this map as opaque (see [DashboardCardPreferencesRepository]) —
/// only the provider/widget layer interprets it, keyed by [kind].
class DashboardCardConfigKeys {
  static const gaugeMode = 'gauge_mode';
  static const trendMetric = 'trend_metric';
  static const trendChartType = 'trend_chart_type';
}

/// One card's show/hide state, position, and (for gauge/trend cards) mode
/// config, as stored per-device. [id] is the stable identity used for
/// persistence and UI keys — it is *not* the same as [kind], since a user
/// can add more than one card of the same kind (e.g. two trend cards for
/// different metrics). For the two default kinds (calendar, insights)
/// there is always exactly one instance and its [id] equals [kind.name],
/// matching the identity every pre-visualization backup/row already uses.
class DashboardCardInstance {
  const DashboardCardInstance({
    required this.id,
    required this.kind,
    required this.visible,
    required this.order,
    this.config = const {},
  });

  final String id;
  final DashboardCardKind kind;
  final bool visible;
  final int order;

  /// Opaque string key-value config, e.g. `{'gauge_mode': 'daysSinceLastPeriod'}`.
  /// Empty for calendar/insights, which have no configurable mode.
  final Map<String, String> config;

  GaugeCardMode get gaugeMode {
    final raw = config[DashboardCardConfigKeys.gaugeMode];
    return GaugeCardMode.values.firstWhere(
      (mode) => mode.name == raw,
      orElse: () => GaugeCardMode.daysSinceLastPeriod,
    );
  }

  TrendCardMetric get trendMetric {
    final raw = config[DashboardCardConfigKeys.trendMetric];
    return TrendCardMetric.values.firstWhere(
      (metric) => metric.name == raw,
      orElse: () => TrendCardMetric.previousCycleLengths,
    );
  }

  TrendChartType get trendChartType {
    final raw = config[DashboardCardConfigKeys.trendChartType];
    return TrendChartType.values.firstWhere(
      (type) => type.name == raw,
      orElse: () => TrendChartType.bar,
    );
  }

  /// Value equality (not identity) — needed so the gauge/trend display
  /// providers (family providers keyed on the instance itself) cache and
  /// invalidate correctly instead of treating every rebuild's instance as
  /// a brand-new cache key.
  @override
  bool operator ==(Object other) {
    return other is DashboardCardInstance &&
        other.id == id &&
        other.kind == kind &&
        other.visible == visible &&
        other.order == order &&
        _mapEquals(other.config, config);
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    visible,
    order,
    Object.hashAllUnordered(
      config.entries.map((e) => Object.hash(e.key, e.value)),
    ),
  );

  DashboardCardInstance copyWith({
    bool? visible,
    int? order,
    Map<String, String>? config,
  }) {
    return DashboardCardInstance(
      id: id,
      kind: kind,
      visible: visible ?? this.visible,
      order: order ?? this.order,
      config: config ?? this.config,
    );
  }

  /// Returns a copy with [key] set to [value] in [config].
  DashboardCardInstance withConfigValue(String key, String value) {
    return copyWith(config: {...config, key: value});
  }
}

/// Builds a new gauge card instance with a fresh, stable [id] — distinct
/// from every other instance even if another gauge card already exists.
DashboardCardInstance newGaugeCardInstance({
  required int order,
  GaugeCardMode mode = GaugeCardMode.daysSinceLastPeriod,
}) {
  return DashboardCardInstance(
    id: _newInstanceId(DashboardCardKind.gauge),
    kind: DashboardCardKind.gauge,
    visible: true,
    order: order,
    config: {DashboardCardConfigKeys.gaugeMode: mode.name},
  );
}

/// Builds a new trend card instance with a fresh, stable [id].
DashboardCardInstance newTrendCardInstance({
  required int order,
  TrendCardMetric metric = TrendCardMetric.previousCycleLengths,
  TrendChartType chartType = TrendChartType.bar,
}) {
  return DashboardCardInstance(
    id: _newInstanceId(DashboardCardKind.trend),
    kind: DashboardCardKind.trend,
    visible: true,
    order: order,
    config: {
      DashboardCardConfigKeys.trendMetric: metric.name,
      DashboardCardConfigKeys.trendChartType: chartType.name,
    },
  );
}

bool _mapEquals(Map<String, String> a, Map<String, String> b) {
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) return false;
  }
  return true;
}

/// A microsecond timestamp is unique enough here: cards are only ever
/// added one at a time, by one user, on one device — there's no
/// concurrent-writer scenario an actual UUID would be guarding against,
/// and pulling in a `uuid` dependency for that would cut against
/// "Lightweight by Default" in CLAUDE.md for no real benefit.
String _newInstanceId(DashboardCardKind kind) {
  return '${kind.name}-${DateTime.now().microsecondsSinceEpoch}';
}
