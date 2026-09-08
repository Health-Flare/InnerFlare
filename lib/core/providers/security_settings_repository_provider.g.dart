// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'security_settings_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(securitySettingsRepository)
final securitySettingsRepositoryProvider =
    SecuritySettingsRepositoryProvider._();

final class SecuritySettingsRepositoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<SecuritySettingsRepository>,
          SecuritySettingsRepository,
          FutureOr<SecuritySettingsRepository>
        >
    with
        $FutureModifier<SecuritySettingsRepository>,
        $FutureProvider<SecuritySettingsRepository> {
  SecuritySettingsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'securitySettingsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$securitySettingsRepositoryHash();

  @$internal
  @override
  $FutureProviderElement<SecuritySettingsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SecuritySettingsRepository> create(Ref ref) {
    return securitySettingsRepository(ref);
  }
}

String _$securitySettingsRepositoryHash() =>
    r'90e81386aa9aa50466f4c1d598adeec8e9a9bc35';
