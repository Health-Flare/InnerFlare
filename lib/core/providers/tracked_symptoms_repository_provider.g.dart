// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tracked_symptoms_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(trackedSymptomsRepository)
final trackedSymptomsRepositoryProvider = TrackedSymptomsRepositoryProvider._();

final class TrackedSymptomsRepositoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<TrackedSymptomsRepository>,
          TrackedSymptomsRepository,
          FutureOr<TrackedSymptomsRepository>
        >
    with
        $FutureModifier<TrackedSymptomsRepository>,
        $FutureProvider<TrackedSymptomsRepository> {
  TrackedSymptomsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'trackedSymptomsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$trackedSymptomsRepositoryHash();

  @$internal
  @override
  $FutureProviderElement<TrackedSymptomsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TrackedSymptomsRepository> create(Ref ref) {
    return trackedSymptomsRepository(ref);
  }
}

String _$trackedSymptomsRepositoryHash() =>
    r'ac09d5d4d71ae7181e235864e0c9ec97a736f2c5';
