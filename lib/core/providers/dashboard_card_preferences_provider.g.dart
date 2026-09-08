// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_card_preferences_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$dashboardCardPreferencesNotifierHash() =>
    r'5512cea45a3f62570f85128e7370019496d11175';

/// The dashboard's customizable card layout — show/hide and order
/// (docs/features/dashboard.feature). Backs both the dashboard screen's
/// rendering and the customization screen's controls.
///
/// Copied from [DashboardCardPreferencesNotifier].
@ProviderFor(DashboardCardPreferencesNotifier)
final dashboardCardPreferencesNotifierProvider =
    AutoDisposeAsyncNotifierProvider<
      DashboardCardPreferencesNotifier,
      List<DashboardCardPreference>
    >.internal(
      DashboardCardPreferencesNotifier.new,
      name: r'dashboardCardPreferencesNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$dashboardCardPreferencesNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$DashboardCardPreferencesNotifier =
    AutoDisposeAsyncNotifier<List<DashboardCardPreference>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
