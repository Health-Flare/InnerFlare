// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_card_preferences_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The dashboard's customizable card layout — show/hide and order
/// (docs/features/dashboard.feature). Backs both the dashboard screen's
/// rendering and the customization screen's controls.

@ProviderFor(DashboardCardPreferencesNotifier)
final dashboardCardPreferencesProvider =
    DashboardCardPreferencesNotifierProvider._();

/// The dashboard's customizable card layout — show/hide and order
/// (docs/features/dashboard.feature). Backs both the dashboard screen's
/// rendering and the customization screen's controls.
final class DashboardCardPreferencesNotifierProvider
    extends
        $AsyncNotifierProvider<
          DashboardCardPreferencesNotifier,
          List<DashboardCardPreference>
        > {
  /// The dashboard's customizable card layout — show/hide and order
  /// (docs/features/dashboard.feature). Backs both the dashboard screen's
  /// rendering and the customization screen's controls.
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
    r'31e0983507ea60abfc013131d95c80f4d53493a4';

/// The dashboard's customizable card layout — show/hide and order
/// (docs/features/dashboard.feature). Backs both the dashboard screen's
/// rendering and the customization screen's controls.

abstract class _$DashboardCardPreferencesNotifier
    extends $AsyncNotifier<List<DashboardCardPreference>> {
  FutureOr<List<DashboardCardPreference>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<DashboardCardPreference>>,
              List<DashboardCardPreference>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<DashboardCardPreference>>,
                List<DashboardCardPreference>
              >,
              AsyncValue<List<DashboardCardPreference>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
