// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$appDatabaseHash() => r'51c82e3e8415e83729d47a802dcba6cc38a23e5f';

/// Opens the encrypted on-device database once per app session and keeps
/// it alive — see [AppDatabase] for what "encrypted" and "on-device" mean
/// in practice.
///
/// Copied from [appDatabase].
@ProviderFor(appDatabase)
final appDatabaseProvider = FutureProvider<Database>.internal(
  appDatabase,
  name: r'appDatabaseProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$appDatabaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AppDatabaseRef = FutureProviderRef<Database>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
