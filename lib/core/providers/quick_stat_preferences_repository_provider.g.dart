// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quick_stat_preferences_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(quickStatPreferencesRepository)
final quickStatPreferencesRepositoryProvider =
    QuickStatPreferencesRepositoryProvider._();

final class QuickStatPreferencesRepositoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<QuickStatPreferencesRepository>,
          QuickStatPreferencesRepository,
          FutureOr<QuickStatPreferencesRepository>
        >
    with
        $FutureModifier<QuickStatPreferencesRepository>,
        $FutureProvider<QuickStatPreferencesRepository> {
  QuickStatPreferencesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'quickStatPreferencesRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$quickStatPreferencesRepositoryHash();

  @$internal
  @override
  $FutureProviderElement<QuickStatPreferencesRepository> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<QuickStatPreferencesRepository> create(Ref ref) {
    return quickStatPreferencesRepository(ref);
  }
}

String _$quickStatPreferencesRepositoryHash() =>
    r'7c05c4b3a2d64de16e36da76bfb9dba57ebef827';
