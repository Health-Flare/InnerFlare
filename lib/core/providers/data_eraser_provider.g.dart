// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_eraser_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The service behind Settings > Erase all data
/// (docs/features/erase_data.feature). A provider so widget tests can
/// swap in a fake or point it at temp directories.

@ProviderFor(dataEraser)
final dataEraserProvider = DataEraserProvider._();

/// The service behind Settings > Erase all data
/// (docs/features/erase_data.feature). A provider so widget tests can
/// swap in a fake or point it at temp directories.

final class DataEraserProvider
    extends $FunctionalProvider<DataEraser, DataEraser, DataEraser>
    with $Provider<DataEraser> {
  /// The service behind Settings > Erase all data
  /// (docs/features/erase_data.feature). A provider so widget tests can
  /// swap in a fake or point it at temp directories.
  DataEraserProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dataEraserProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dataEraserHash();

  @$internal
  @override
  $ProviderElement<DataEraser> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DataEraser create(Ref ref) {
    return dataEraser(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DataEraser value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DataEraser>(value),
    );
  }
}

String _$dataEraserHash() => r'656f65071b53701f48d494c6f357a6e6daaa6a7f';
