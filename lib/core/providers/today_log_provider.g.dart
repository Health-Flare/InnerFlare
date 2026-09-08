// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'today_log_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$todayLogHash() => r'accff2ea886223e86abb5cb80ecb7619e0b0c9ef';

/// Whether — and how — today has been logged. Backs the dashboard's
/// persistent "log today" entry point (docs/features/log.feature).
///
/// Copied from [TodayLog].
@ProviderFor(TodayLog)
final todayLogProvider =
    AutoDisposeAsyncNotifierProvider<TodayLog, CycleDayLog?>.internal(
      TodayLog.new,
      name: r'todayLogProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$todayLogHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$TodayLog = AutoDisposeAsyncNotifier<CycleDayLog?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
