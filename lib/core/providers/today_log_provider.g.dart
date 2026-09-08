// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'today_log_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$todayLogHash() => r'd8d14f2fba0a7487fd9015b1d891bba331e7a8b8';

/// Whether — and how — today has been logged. A thin wrapper over
/// [cycleDayLogEntryProvider] for today's date; backs the dashboard's
/// persistent "log today" entry point (docs/features/log.feature).
///
/// Copied from [todayLog].
@ProviderFor(todayLog)
final todayLogProvider = AutoDisposeFutureProvider<CycleDayLog?>.internal(
  todayLog,
  name: r'todayLogProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$todayLogHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TodayLogRef = AutoDisposeFutureProviderRef<CycleDayLog?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
