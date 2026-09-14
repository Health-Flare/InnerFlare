// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quick_stat_displays_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Computes both slots' display values live from the same period-start
/// and cycle-length data as docs/features/insights.feature — no separate
/// cached calculation to keep in sync (see "Quick stats recompute live
/// from the same data as Insights").

@ProviderFor(quickStatDisplays)
final quickStatDisplaysProvider = QuickStatDisplaysProvider._();

/// Computes both slots' display values live from the same period-start
/// and cycle-length data as docs/features/insights.feature — no separate
/// cached calculation to keep in sync (see "Quick stats recompute live
/// from the same data as Insights").

final class QuickStatDisplaysProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<QuickStatDisplay>>,
          List<QuickStatDisplay>,
          FutureOr<List<QuickStatDisplay>>
        >
    with
        $FutureModifier<List<QuickStatDisplay>>,
        $FutureProvider<List<QuickStatDisplay>> {
  /// Computes both slots' display values live from the same period-start
  /// and cycle-length data as docs/features/insights.feature — no separate
  /// cached calculation to keep in sync (see "Quick stats recompute live
  /// from the same data as Insights").
  QuickStatDisplaysProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'quickStatDisplaysProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$quickStatDisplaysHash();

  @$internal
  @override
  $FutureProviderElement<List<QuickStatDisplay>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<QuickStatDisplay>> create(Ref ref) {
    return quickStatDisplays(ref);
  }
}

String _$quickStatDisplaysHash() => r'2e4d71cdac59cefc9f9bc7eb38161200d18cd09d';
