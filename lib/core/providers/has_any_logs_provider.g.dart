// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'has_any_logs_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$hasAnyLogsHash() => r'518666a35d6ff54b500b859b5bb69e75c04ca367';

/// Whether the user has ever logged a day — distinguishes "no data yet"
/// from "nothing in this particular month" for the calendar's empty state
/// (docs/features/calendar.feature, "Empty calendar before any logging").
///
/// Copied from [hasAnyLogs].
@ProviderFor(hasAnyLogs)
final hasAnyLogsProvider = AutoDisposeFutureProvider<bool>.internal(
  hasAnyLogs,
  name: r'hasAnyLogsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$hasAnyLogsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HasAnyLogsRef = AutoDisposeFutureProviderRef<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
