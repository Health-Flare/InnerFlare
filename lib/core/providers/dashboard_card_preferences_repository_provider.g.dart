// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_card_preferences_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(dashboardCardPreferencesRepository)
final dashboardCardPreferencesRepositoryProvider =
    DashboardCardPreferencesRepositoryProvider._();

final class DashboardCardPreferencesRepositoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<DashboardCardPreferencesRepository>,
          DashboardCardPreferencesRepository,
          FutureOr<DashboardCardPreferencesRepository>
        >
    with
        $FutureModifier<DashboardCardPreferencesRepository>,
        $FutureProvider<DashboardCardPreferencesRepository> {
  DashboardCardPreferencesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dashboardCardPreferencesRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$dashboardCardPreferencesRepositoryHash();

  @$internal
  @override
  $FutureProviderElement<DashboardCardPreferencesRepository> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DashboardCardPreferencesRepository> create(Ref ref) {
    return dashboardCardPreferencesRepository(ref);
  }
}

String _$dashboardCardPreferencesRepositoryHash() =>
    r'9a48092faef1cc68f6ab66208e73d613b2796396';
