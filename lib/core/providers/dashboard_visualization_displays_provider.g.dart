// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_visualization_displays_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Resolves [instance] (a gauge card) to its live display values, computed
/// from the same period-start data as docs/features/insights.feature and
/// docs/features/quick_stats.feature — no separate cached calculation to
/// drift out of sync.

@ProviderFor(gaugeCardDisplay)
final gaugeCardDisplayProvider = GaugeCardDisplayFamily._();

/// Resolves [instance] (a gauge card) to its live display values, computed
/// from the same period-start data as docs/features/insights.feature and
/// docs/features/quick_stats.feature — no separate cached calculation to
/// drift out of sync.

final class GaugeCardDisplayProvider
    extends
        $FunctionalProvider<
          AsyncValue<GaugeCardDisplay>,
          GaugeCardDisplay,
          FutureOr<GaugeCardDisplay>
        >
    with $FutureModifier<GaugeCardDisplay>, $FutureProvider<GaugeCardDisplay> {
  /// Resolves [instance] (a gauge card) to its live display values, computed
  /// from the same period-start data as docs/features/insights.feature and
  /// docs/features/quick_stats.feature — no separate cached calculation to
  /// drift out of sync.
  GaugeCardDisplayProvider._({
    required GaugeCardDisplayFamily super.from,
    required DashboardCardInstance super.argument,
  }) : super(
         retry: null,
         name: r'gaugeCardDisplayProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$gaugeCardDisplayHash();

  @override
  String toString() {
    return r'gaugeCardDisplayProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<GaugeCardDisplay> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<GaugeCardDisplay> create(Ref ref) {
    final argument = this.argument as DashboardCardInstance;
    return gaugeCardDisplay(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is GaugeCardDisplayProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$gaugeCardDisplayHash() => r'18e9829904c6f5bdf2f4e22da5ef7af9ee11de51';

/// Resolves [instance] (a gauge card) to its live display values, computed
/// from the same period-start data as docs/features/insights.feature and
/// docs/features/quick_stats.feature — no separate cached calculation to
/// drift out of sync.

final class GaugeCardDisplayFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<GaugeCardDisplay>,
          DashboardCardInstance
        > {
  GaugeCardDisplayFamily._()
    : super(
        retry: null,
        name: r'gaugeCardDisplayProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Resolves [instance] (a gauge card) to its live display values, computed
  /// from the same period-start data as docs/features/insights.feature and
  /// docs/features/quick_stats.feature — no separate cached calculation to
  /// drift out of sync.

  GaugeCardDisplayProvider call(DashboardCardInstance instance) =>
      GaugeCardDisplayProvider._(argument: instance, from: this);

  @override
  String toString() => r'gaugeCardDisplayProvider';
}

/// Resolves [instance] (a trend card) to its live display values. Only
/// [TrendCardMetric.previousCycleLengths] has real data behind it today —
/// see the TODO on [TrendCardMetric] in lib/models/dashboard_card.dart for
/// what the other catalog entries still need before they can compute
/// anything.

@ProviderFor(trendCardDisplay)
final trendCardDisplayProvider = TrendCardDisplayFamily._();

/// Resolves [instance] (a trend card) to its live display values. Only
/// [TrendCardMetric.previousCycleLengths] has real data behind it today —
/// see the TODO on [TrendCardMetric] in lib/models/dashboard_card.dart for
/// what the other catalog entries still need before they can compute
/// anything.

final class TrendCardDisplayProvider
    extends
        $FunctionalProvider<
          AsyncValue<TrendCardDisplay>,
          TrendCardDisplay,
          FutureOr<TrendCardDisplay>
        >
    with $FutureModifier<TrendCardDisplay>, $FutureProvider<TrendCardDisplay> {
  /// Resolves [instance] (a trend card) to its live display values. Only
  /// [TrendCardMetric.previousCycleLengths] has real data behind it today —
  /// see the TODO on [TrendCardMetric] in lib/models/dashboard_card.dart for
  /// what the other catalog entries still need before they can compute
  /// anything.
  TrendCardDisplayProvider._({
    required TrendCardDisplayFamily super.from,
    required DashboardCardInstance super.argument,
  }) : super(
         retry: null,
         name: r'trendCardDisplayProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$trendCardDisplayHash();

  @override
  String toString() {
    return r'trendCardDisplayProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<TrendCardDisplay> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TrendCardDisplay> create(Ref ref) {
    final argument = this.argument as DashboardCardInstance;
    return trendCardDisplay(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TrendCardDisplayProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$trendCardDisplayHash() => r'1e4e1479193c75f4fd9a46720227f1449163fad5';

/// Resolves [instance] (a trend card) to its live display values. Only
/// [TrendCardMetric.previousCycleLengths] has real data behind it today —
/// see the TODO on [TrendCardMetric] in lib/models/dashboard_card.dart for
/// what the other catalog entries still need before they can compute
/// anything.

final class TrendCardDisplayFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<TrendCardDisplay>,
          DashboardCardInstance
        > {
  TrendCardDisplayFamily._()
    : super(
        retry: null,
        name: r'trendCardDisplayProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Resolves [instance] (a trend card) to its live display values. Only
  /// [TrendCardMetric.previousCycleLengths] has real data behind it today —
  /// see the TODO on [TrendCardMetric] in lib/models/dashboard_card.dart for
  /// what the other catalog entries still need before they can compute
  /// anything.

  TrendCardDisplayProvider call(DashboardCardInstance instance) =>
      TrendCardDisplayProvider._(argument: instance, from: this);

  @override
  String toString() => r'trendCardDisplayProvider';
}
