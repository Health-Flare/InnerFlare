// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nudge_state_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(nudgeStateRepository)
final nudgeStateRepositoryProvider = NudgeStateRepositoryProvider._();

final class NudgeStateRepositoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<NudgeStateRepository>,
          NudgeStateRepository,
          FutureOr<NudgeStateRepository>
        >
    with
        $FutureModifier<NudgeStateRepository>,
        $FutureProvider<NudgeStateRepository> {
  NudgeStateRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nudgeStateRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nudgeStateRepositoryHash();

  @$internal
  @override
  $FutureProviderElement<NudgeStateRepository> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<NudgeStateRepository> create(Ref ref) {
    return nudgeStateRepository(ref);
  }
}

String _$nudgeStateRepositoryHash() =>
    r'8047a0c8cf8170800205d76e07f0f9c2f4c5a362';
