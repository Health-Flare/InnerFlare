// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'disclaimer_acknowledged_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the user has continued past the first-run privacy and
/// not-a-medical-device disclaimer
/// (docs/features/first_run_disclaimer.feature).
///
/// Stored in `security_settings`, which is per-device and never exported.

@ProviderFor(DisclaimerAcknowledgedNotifier)
final disclaimerAcknowledgedProvider =
    DisclaimerAcknowledgedNotifierProvider._();

/// Whether the user has continued past the first-run privacy and
/// not-a-medical-device disclaimer
/// (docs/features/first_run_disclaimer.feature).
///
/// Stored in `security_settings`, which is per-device and never exported.
final class DisclaimerAcknowledgedNotifierProvider
    extends $AsyncNotifierProvider<DisclaimerAcknowledgedNotifier, bool> {
  /// Whether the user has continued past the first-run privacy and
  /// not-a-medical-device disclaimer
  /// (docs/features/first_run_disclaimer.feature).
  ///
  /// Stored in `security_settings`, which is per-device and never exported.
  DisclaimerAcknowledgedNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'disclaimerAcknowledgedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$disclaimerAcknowledgedNotifierHash();

  @$internal
  @override
  DisclaimerAcknowledgedNotifier create() => DisclaimerAcknowledgedNotifier();
}

String _$disclaimerAcknowledgedNotifierHash() =>
    r'6bdb066c834d6b8c7d1880c9e2b317801385d508';

/// Whether the user has continued past the first-run privacy and
/// not-a-medical-device disclaimer
/// (docs/features/first_run_disclaimer.feature).
///
/// Stored in `security_settings`, which is per-device and never exported.

abstract class _$DisclaimerAcknowledgedNotifier extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
