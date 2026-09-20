// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cycle_detail_rows_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Every complete cycle, most-recent-first, backing the cycle detail
/// table (docs/features/dashboard_visualizations.feature, "The cycle
/// detail table lists every complete cycle..."). Shared by both trend
/// cards that lead here — see [CycleDetailScreen] — since they present
/// the same underlying period-start data two different ways.

@ProviderFor(cycleDetailRows)
final cycleDetailRowsProvider = CycleDetailRowsProvider._();

/// Every complete cycle, most-recent-first, backing the cycle detail
/// table (docs/features/dashboard_visualizations.feature, "The cycle
/// detail table lists every complete cycle..."). Shared by both trend
/// cards that lead here — see [CycleDetailScreen] — since they present
/// the same underlying period-start data two different ways.

final class CycleDetailRowsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<cycle_math.CycleDetailRow>>,
          List<cycle_math.CycleDetailRow>,
          FutureOr<List<cycle_math.CycleDetailRow>>
        >
    with
        $FutureModifier<List<cycle_math.CycleDetailRow>>,
        $FutureProvider<List<cycle_math.CycleDetailRow>> {
  /// Every complete cycle, most-recent-first, backing the cycle detail
  /// table (docs/features/dashboard_visualizations.feature, "The cycle
  /// detail table lists every complete cycle..."). Shared by both trend
  /// cards that lead here — see [CycleDetailScreen] — since they present
  /// the same underlying period-start data two different ways.
  CycleDetailRowsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cycleDetailRowsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cycleDetailRowsHash();

  @$internal
  @override
  $FutureProviderElement<List<cycle_math.CycleDetailRow>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<cycle_math.CycleDetailRow>> create(Ref ref) {
    return cycleDetailRows(ref);
  }
}

String _$cycleDetailRowsHash() => r'deebf4cdd9477dfc738b02ab7eda657e0a5ec205';
