// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cycle_day_log_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(cycleDayLogRepository)
final cycleDayLogRepositoryProvider = CycleDayLogRepositoryProvider._();

final class CycleDayLogRepositoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<CycleDayLogRepository>,
          CycleDayLogRepository,
          FutureOr<CycleDayLogRepository>
        >
    with
        $FutureModifier<CycleDayLogRepository>,
        $FutureProvider<CycleDayLogRepository> {
  CycleDayLogRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cycleDayLogRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cycleDayLogRepositoryHash();

  @$internal
  @override
  $FutureProviderElement<CycleDayLogRepository> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CycleDayLogRepository> create(Ref ref) {
    return cycleDayLogRepository(ref);
  }
}

String _$cycleDayLogRepositoryHash() =>
    r'4ed17f05b72ceb65fdec6f8f58226759a39c6e35';
