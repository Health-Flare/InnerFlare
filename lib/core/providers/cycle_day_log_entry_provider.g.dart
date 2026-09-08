// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cycle_day_log_entry_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The saved entry (if any) for a single date — backs the log-entry
/// screen for today or any prior day (docs/features/log.feature,
/// "Back-logging a missed day is exactly as fast as logging today").
///
/// [date] must be date-only (no time-of-day component) so the same
/// calendar day always resolves to the same provider instance.

@ProviderFor(CycleDayLogEntry)
final cycleDayLogEntryProvider = CycleDayLogEntryFamily._();

/// The saved entry (if any) for a single date — backs the log-entry
/// screen for today or any prior day (docs/features/log.feature,
/// "Back-logging a missed day is exactly as fast as logging today").
///
/// [date] must be date-only (no time-of-day component) so the same
/// calendar day always resolves to the same provider instance.
final class CycleDayLogEntryProvider
    extends $AsyncNotifierProvider<CycleDayLogEntry, CycleDayLog?> {
  /// The saved entry (if any) for a single date — backs the log-entry
  /// screen for today or any prior day (docs/features/log.feature,
  /// "Back-logging a missed day is exactly as fast as logging today").
  ///
  /// [date] must be date-only (no time-of-day component) so the same
  /// calendar day always resolves to the same provider instance.
  CycleDayLogEntryProvider._({
    required CycleDayLogEntryFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'cycleDayLogEntryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$cycleDayLogEntryHash();

  @override
  String toString() {
    return r'cycleDayLogEntryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  CycleDayLogEntry create() => CycleDayLogEntry();

  @override
  bool operator ==(Object other) {
    return other is CycleDayLogEntryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$cycleDayLogEntryHash() => r'695ccb5522a889c6c9a895117f0524b6dabe4cb3';

/// The saved entry (if any) for a single date — backs the log-entry
/// screen for today or any prior day (docs/features/log.feature,
/// "Back-logging a missed day is exactly as fast as logging today").
///
/// [date] must be date-only (no time-of-day component) so the same
/// calendar day always resolves to the same provider instance.

final class CycleDayLogEntryFamily extends $Family
    with
        $ClassFamilyOverride<
          CycleDayLogEntry,
          AsyncValue<CycleDayLog?>,
          CycleDayLog?,
          FutureOr<CycleDayLog?>,
          DateTime
        > {
  CycleDayLogEntryFamily._()
    : super(
        retry: null,
        name: r'cycleDayLogEntryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The saved entry (if any) for a single date — backs the log-entry
  /// screen for today or any prior day (docs/features/log.feature,
  /// "Back-logging a missed day is exactly as fast as logging today").
  ///
  /// [date] must be date-only (no time-of-day component) so the same
  /// calendar day always resolves to the same provider instance.

  CycleDayLogEntryProvider call(DateTime date) =>
      CycleDayLogEntryProvider._(argument: date, from: this);

  @override
  String toString() => r'cycleDayLogEntryProvider';
}

/// The saved entry (if any) for a single date — backs the log-entry
/// screen for today or any prior day (docs/features/log.feature,
/// "Back-logging a missed day is exactly as fast as logging today").
///
/// [date] must be date-only (no time-of-day component) so the same
/// calendar day always resolves to the same provider instance.

abstract class _$CycleDayLogEntry extends $AsyncNotifier<CycleDayLog?> {
  late final _$args = ref.$arg as DateTime;
  DateTime get date => _$args;

  FutureOr<CycleDayLog?> build(DateTime date);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<CycleDayLog?>, CycleDayLog?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<CycleDayLog?>, CycleDayLog?>,
              AsyncValue<CycleDayLog?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
