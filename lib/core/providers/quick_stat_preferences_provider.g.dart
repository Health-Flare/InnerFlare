// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quick_stat_preferences_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The dashboard's two customizable quick stat slots (docs/features/
/// quick_stats.feature). Backs both the dashboard's display and the
/// customization screen's controls.

@ProviderFor(QuickStatPreferencesNotifier)
final quickStatPreferencesProvider = QuickStatPreferencesNotifierProvider._();

/// The dashboard's two customizable quick stat slots (docs/features/
/// quick_stats.feature). Backs both the dashboard's display and the
/// customization screen's controls.
final class QuickStatPreferencesNotifierProvider
    extends
        $AsyncNotifierProvider<
          QuickStatPreferencesNotifier,
          List<QuickStatPreference>
        > {
  /// The dashboard's two customizable quick stat slots (docs/features/
  /// quick_stats.feature). Backs both the dashboard's display and the
  /// customization screen's controls.
  QuickStatPreferencesNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'quickStatPreferencesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$quickStatPreferencesNotifierHash();

  @$internal
  @override
  QuickStatPreferencesNotifier create() => QuickStatPreferencesNotifier();
}

String _$quickStatPreferencesNotifierHash() =>
    r'2e7f5defa0eb0e95e28ce7b74a8f4cf1f27c16d2';

/// The dashboard's two customizable quick stat slots (docs/features/
/// quick_stats.feature). Backs both the dashboard's display and the
/// customization screen's controls.

abstract class _$QuickStatPreferencesNotifier
    extends $AsyncNotifier<List<QuickStatPreference>> {
  FutureOr<List<QuickStatPreference>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<QuickStatPreference>>,
              List<QuickStatPreference>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<QuickStatPreference>>,
                List<QuickStatPreference>
              >,
              AsyncValue<List<QuickStatPreference>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
