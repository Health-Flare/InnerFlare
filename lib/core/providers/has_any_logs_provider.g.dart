// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'has_any_logs_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the user has ever logged a day — distinguishes "no data yet"
/// from "nothing in this particular month" for the calendar's empty state
/// (docs/features/calendar.feature, "Empty calendar before any logging").

@ProviderFor(hasAnyLogs)
final hasAnyLogsProvider = HasAnyLogsProvider._();

/// Whether the user has ever logged a day — distinguishes "no data yet"
/// from "nothing in this particular month" for the calendar's empty state
/// (docs/features/calendar.feature, "Empty calendar before any logging").

final class HasAnyLogsProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Whether the user has ever logged a day — distinguishes "no data yet"
  /// from "nothing in this particular month" for the calendar's empty state
  /// (docs/features/calendar.feature, "Empty calendar before any logging").
  HasAnyLogsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hasAnyLogsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hasAnyLogsHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return hasAnyLogs(ref);
  }
}

String _$hasAnyLogsHash() => r'518666a35d6ff54b500b859b5bb69e75c04ca367';
