// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_month_logs_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Every logged day in the month containing [month], keyed by date-only —
/// backs the calendar's month view (docs/features/calendar.feature).
///
/// [month] must be the first of the month (no time-of-day component) so
/// the same month always resolves to the same provider instance.

@ProviderFor(calendarMonthLogs)
final calendarMonthLogsProvider = CalendarMonthLogsFamily._();

/// Every logged day in the month containing [month], keyed by date-only —
/// backs the calendar's month view (docs/features/calendar.feature).
///
/// [month] must be the first of the month (no time-of-day component) so
/// the same month always resolves to the same provider instance.

final class CalendarMonthLogsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<DateTime, CycleDayLog>>,
          Map<DateTime, CycleDayLog>,
          FutureOr<Map<DateTime, CycleDayLog>>
        >
    with
        $FutureModifier<Map<DateTime, CycleDayLog>>,
        $FutureProvider<Map<DateTime, CycleDayLog>> {
  /// Every logged day in the month containing [month], keyed by date-only —
  /// backs the calendar's month view (docs/features/calendar.feature).
  ///
  /// [month] must be the first of the month (no time-of-day component) so
  /// the same month always resolves to the same provider instance.
  CalendarMonthLogsProvider._({
    required CalendarMonthLogsFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'calendarMonthLogsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$calendarMonthLogsHash();

  @override
  String toString() {
    return r'calendarMonthLogsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Map<DateTime, CycleDayLog>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<DateTime, CycleDayLog>> create(Ref ref) {
    final argument = this.argument as DateTime;
    return calendarMonthLogs(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CalendarMonthLogsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$calendarMonthLogsHash() => r'd6bb99b23ec7f4eb1f16ccbf3f6dd841f302c3aa';

/// Every logged day in the month containing [month], keyed by date-only —
/// backs the calendar's month view (docs/features/calendar.feature).
///
/// [month] must be the first of the month (no time-of-day component) so
/// the same month always resolves to the same provider instance.

final class CalendarMonthLogsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<Map<DateTime, CycleDayLog>>,
          DateTime
        > {
  CalendarMonthLogsFamily._()
    : super(
        retry: null,
        name: r'calendarMonthLogsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Every logged day in the month containing [month], keyed by date-only —
  /// backs the calendar's month view (docs/features/calendar.feature).
  ///
  /// [month] must be the first of the month (no time-of-day component) so
  /// the same month always resolves to the same provider instance.

  CalendarMonthLogsProvider call(DateTime month) =>
      CalendarMonthLogsProvider._(argument: month, from: this);

  @override
  String toString() => r'calendarMonthLogsProvider';
}
