// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cycle_insights_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(cycleInsights)
final cycleInsightsProvider = CycleInsightsProvider._();

final class CycleInsightsProvider
    extends
        $FunctionalProvider<
          AsyncValue<CycleInsights>,
          CycleInsights,
          FutureOr<CycleInsights>
        >
    with $FutureModifier<CycleInsights>, $FutureProvider<CycleInsights> {
  CycleInsightsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cycleInsightsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cycleInsightsHash();

  @$internal
  @override
  $FutureProviderElement<CycleInsights> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CycleInsights> create(Ref ref) {
    return cycleInsights(ref);
  }
}

String _$cycleInsightsHash() => r'd178ece6172fab4a84fd430d2c3b4b86f5c2cea4';
