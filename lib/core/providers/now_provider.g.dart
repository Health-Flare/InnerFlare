// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'now_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$nowHash() => r'a18fd0a1c525818279254bbe775974fc6f13cf60';

/// The current time, as a provider — so anything that needs "now" can be
/// given a fixed value in tests instead of depending on [DateTime.now]
/// directly (same rule CLAUDE.md sets for the pure cycle-math functions).
///
/// Copied from [now].
@ProviderFor(now)
final nowProvider = Provider<DateTime Function()>.internal(
  now,
  name: r'nowProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$nowHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NowRef = ProviderRef<DateTime Function()>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
