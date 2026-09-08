// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cycle_prediction_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(cyclePrediction)
final cyclePredictionProvider = CyclePredictionProvider._();

final class CyclePredictionProvider
    extends
        $FunctionalProvider<
          AsyncValue<CyclePrediction>,
          CyclePrediction,
          FutureOr<CyclePrediction>
        >
    with $FutureModifier<CyclePrediction>, $FutureProvider<CyclePrediction> {
  CyclePredictionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cyclePredictionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cyclePredictionHash();

  @$internal
  @override
  $FutureProviderElement<CyclePrediction> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CyclePrediction> create(Ref ref) {
    return cyclePrediction(ref);
  }
}

String _$cyclePredictionHash() => r'4f1b927e11b0d172a295add368296aa96dbdeb67';
