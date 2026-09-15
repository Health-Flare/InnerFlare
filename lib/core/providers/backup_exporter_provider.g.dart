// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backup_exporter_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(backupExporter)
final backupExporterProvider = BackupExporterProvider._();

final class BackupExporterProvider
    extends
        $FunctionalProvider<
          AsyncValue<BackupExporter>,
          BackupExporter,
          FutureOr<BackupExporter>
        >
    with $FutureModifier<BackupExporter>, $FutureProvider<BackupExporter> {
  BackupExporterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backupExporterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backupExporterHash();

  @$internal
  @override
  $FutureProviderElement<BackupExporter> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<BackupExporter> create(Ref ref) {
    return backupExporter(ref);
  }
}

String _$backupExporterHash() => r'af8513636291951c8e6d418a9b4e48ac8af04455';
