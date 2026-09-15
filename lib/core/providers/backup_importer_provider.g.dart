// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backup_importer_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(backupImporter)
final backupImporterProvider = BackupImporterProvider._();

final class BackupImporterProvider
    extends
        $FunctionalProvider<
          AsyncValue<BackupImporter>,
          BackupImporter,
          FutureOr<BackupImporter>
        >
    with $FutureModifier<BackupImporter>, $FutureProvider<BackupImporter> {
  BackupImporterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backupImporterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backupImporterHash();

  @$internal
  @override
  $FutureProviderElement<BackupImporter> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<BackupImporter> create(Ref ref) {
    return backupImporter(ref);
  }
}

String _$backupImporterHash() => r'd5116cf3986cebaeebba95bc8522356705f55f9c';
