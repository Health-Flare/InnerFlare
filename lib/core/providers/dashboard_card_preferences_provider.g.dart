// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_card_preferences_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The dashboard's customizable card layout — show/hide, order, add/remove,
/// and per-card mode config (docs/features/dashboard.feature,
/// docs/features/dashboard_visualizations.feature). Backs both the
/// dashboard screen's rendering and the customization/add-card screens'
/// controls. Every mutator here is keyed off [DashboardCardInstance.id],
/// never [DashboardCardKind], since more than one instance of the same
/// kind can exist.

@ProviderFor(DashboardCardPreferencesNotifier)
final dashboardCardPreferencesProvider =
    DashboardCardPreferencesNotifierProvider._();

/// The dashboard's customizable card layout — show/hide, order, add/remove,
/// and per-card mode config (docs/features/dashboard.feature,
/// docs/features/dashboard_visualizations.feature). Backs both the
/// dashboard screen's rendering and the customization/add-card screens'
/// controls. Every mutator here is keyed off [DashboardCardInstance.id],
/// never [DashboardCardKind], since more than one instance of the same
/// kind can exist.
final class DashboardCardPreferencesNotifierProvider
    extends
        $AsyncNotifierProvider<
          DashboardCardPreferencesNotifier,
          List<DashboardCardInstance>
        > {
  /// The dashboard's customizable card layout — show/hide, order, add/remove,
  /// and per-card mode config (docs/features/dashboard.feature,
  /// docs/features/dashboard_visualizations.feature). Backs both the
  /// dashboard screen's rendering and the customization/add-card screens'
  /// controls. Every mutator here is keyed off [DashboardCardInstance.id],
  /// never [DashboardCardKind], since more than one instance of the same
  /// kind can exist.
  DashboardCardPreferencesNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dashboardCardPreferencesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dashboardCardPreferencesNotifierHash();

  @$internal
  @override
  DashboardCardPreferencesNotifier create() =>
      DashboardCardPreferencesNotifier();
}

String _$dashboardCardPreferencesNotifierHash() =>
    r'34716856c4e1fddaae34d8862fd427b6d882515b';

/// The dashboard's customizable card layout — show/hide, order, add/remove,
/// and per-card mode config (docs/features/dashboard.feature,
/// docs/features/dashboard_visualizations.feature). Backs both the
/// dashboard screen's rendering and the customization/add-card screens'
/// controls. Every mutator here is keyed off [DashboardCardInstance.id],
/// never [DashboardCardKind], since more than one instance of the same
/// kind can exist.

abstract class _$DashboardCardPreferencesNotifier
    extends $AsyncNotifier<List<DashboardCardInstance>> {
  FutureOr<List<DashboardCardInstance>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<DashboardCardInstance>>,
              List<DashboardCardInstance>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<DashboardCardInstance>>,
                List<DashboardCardInstance>
              >,
              AsyncValue<List<DashboardCardInstance>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
