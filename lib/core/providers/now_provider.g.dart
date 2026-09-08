// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'now_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The current time, as a provider — so anything that needs "now" can be
/// given a fixed value in tests instead of depending on [DateTime.now]
/// directly (same rule CLAUDE.md sets for the pure cycle-math functions).

@ProviderFor(now)
final nowProvider = NowProvider._();

/// The current time, as a provider — so anything that needs "now" can be
/// given a fixed value in tests instead of depending on [DateTime.now]
/// directly (same rule CLAUDE.md sets for the pure cycle-math functions).

final class NowProvider
    extends
        $FunctionalProvider<
          DateTime Function(),
          DateTime Function(),
          DateTime Function()
        >
    with $Provider<DateTime Function()> {
  /// The current time, as a provider — so anything that needs "now" can be
  /// given a fixed value in tests instead of depending on [DateTime.now]
  /// directly (same rule CLAUDE.md sets for the pure cycle-math functions).
  NowProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nowProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nowHash();

  @$internal
  @override
  $ProviderElement<DateTime Function()> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DateTime Function() create(Ref ref) {
    return now(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime Function() value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime Function()>(value),
    );
  }
}

String _$nowHash() => r'a18fd0a1c525818279254bbe775974fc6f13cf60';
