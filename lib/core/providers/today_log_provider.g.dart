// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'today_log_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether — and how — today has been logged. A thin wrapper over
/// [cycleDayLogEntryProvider] for today's date; backs the dashboard's
/// persistent "log today" entry point (docs/features/log.feature).

@ProviderFor(todayLog)
final todayLogProvider = TodayLogProvider._();

/// Whether — and how — today has been logged. A thin wrapper over
/// [cycleDayLogEntryProvider] for today's date; backs the dashboard's
/// persistent "log today" entry point (docs/features/log.feature).

final class TodayLogProvider
    extends
        $FunctionalProvider<
          AsyncValue<CycleDayLog?>,
          CycleDayLog?,
          FutureOr<CycleDayLog?>
        >
    with $FutureModifier<CycleDayLog?>, $FutureProvider<CycleDayLog?> {
  /// Whether — and how — today has been logged. A thin wrapper over
  /// [cycleDayLogEntryProvider] for today's date; backs the dashboard's
  /// persistent "log today" entry point (docs/features/log.feature).
  TodayLogProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todayLogProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todayLogHash();

  @$internal
  @override
  $FutureProviderElement<CycleDayLog?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CycleDayLog?> create(Ref ref) {
    return todayLog(ref);
  }
}

String _$todayLogHash() => r'd8d14f2fba0a7487fd9015b1d891bba331e7a8b8';
