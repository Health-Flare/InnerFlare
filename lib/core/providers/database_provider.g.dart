// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Opens the encrypted on-device database once per app session and keeps
/// it alive — see [AppDatabase] for what "encrypted" and "on-device" mean
/// in practice.

@ProviderFor(appDatabase)
final appDatabaseProvider = AppDatabaseProvider._();

/// Opens the encrypted on-device database once per app session and keeps
/// it alive — see [AppDatabase] for what "encrypted" and "on-device" mean
/// in practice.

final class AppDatabaseProvider
    extends
        $FunctionalProvider<AsyncValue<Database>, Database, FutureOr<Database>>
    with $FutureModifier<Database>, $FutureProvider<Database> {
  /// Opens the encrypted on-device database once per app session and keeps
  /// it alive — see [AppDatabase] for what "encrypted" and "on-device" mean
  /// in practice.
  AppDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appDatabaseHash();

  @$internal
  @override
  $FutureProviderElement<Database> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Database> create(Ref ref) {
    return appDatabase(ref);
  }
}

String _$appDatabaseHash() => r'51c82e3e8415e83729d47a802dcba6cc38a23e5f';
