// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_month_logs_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$calendarMonthLogsHash() => r'c4678509de8844d6012f02848ad005fd215d8216';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Every logged day in the month containing [month], keyed by date-only —
/// backs the calendar's month view (docs/features/calendar.feature).
///
/// [month] must be the first of the month (no time-of-day component) so
/// the same month always resolves to the same provider instance.
///
/// Copied from [calendarMonthLogs].
@ProviderFor(calendarMonthLogs)
const calendarMonthLogsProvider = CalendarMonthLogsFamily();

/// Every logged day in the month containing [month], keyed by date-only —
/// backs the calendar's month view (docs/features/calendar.feature).
///
/// [month] must be the first of the month (no time-of-day component) so
/// the same month always resolves to the same provider instance.
///
/// Copied from [calendarMonthLogs].
class CalendarMonthLogsFamily
    extends Family<AsyncValue<Map<DateTime, CycleDayLog>>> {
  /// Every logged day in the month containing [month], keyed by date-only —
  /// backs the calendar's month view (docs/features/calendar.feature).
  ///
  /// [month] must be the first of the month (no time-of-day component) so
  /// the same month always resolves to the same provider instance.
  ///
  /// Copied from [calendarMonthLogs].
  const CalendarMonthLogsFamily();

  /// Every logged day in the month containing [month], keyed by date-only —
  /// backs the calendar's month view (docs/features/calendar.feature).
  ///
  /// [month] must be the first of the month (no time-of-day component) so
  /// the same month always resolves to the same provider instance.
  ///
  /// Copied from [calendarMonthLogs].
  CalendarMonthLogsProvider call(DateTime month) {
    return CalendarMonthLogsProvider(month);
  }

  @override
  CalendarMonthLogsProvider getProviderOverride(
    covariant CalendarMonthLogsProvider provider,
  ) {
    return call(provider.month);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'calendarMonthLogsProvider';
}

/// Every logged day in the month containing [month], keyed by date-only —
/// backs the calendar's month view (docs/features/calendar.feature).
///
/// [month] must be the first of the month (no time-of-day component) so
/// the same month always resolves to the same provider instance.
///
/// Copied from [calendarMonthLogs].
class CalendarMonthLogsProvider
    extends AutoDisposeFutureProvider<Map<DateTime, CycleDayLog>> {
  /// Every logged day in the month containing [month], keyed by date-only —
  /// backs the calendar's month view (docs/features/calendar.feature).
  ///
  /// [month] must be the first of the month (no time-of-day component) so
  /// the same month always resolves to the same provider instance.
  ///
  /// Copied from [calendarMonthLogs].
  CalendarMonthLogsProvider(DateTime month)
    : this._internal(
        (ref) => calendarMonthLogs(ref as CalendarMonthLogsRef, month),
        from: calendarMonthLogsProvider,
        name: r'calendarMonthLogsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$calendarMonthLogsHash,
        dependencies: CalendarMonthLogsFamily._dependencies,
        allTransitiveDependencies:
            CalendarMonthLogsFamily._allTransitiveDependencies,
        month: month,
      );

  CalendarMonthLogsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.month,
  }) : super.internal();

  final DateTime month;

  @override
  Override overrideWith(
    FutureOr<Map<DateTime, CycleDayLog>> Function(CalendarMonthLogsRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CalendarMonthLogsProvider._internal(
        (ref) => create(ref as CalendarMonthLogsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        month: month,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Map<DateTime, CycleDayLog>> createElement() {
    return _CalendarMonthLogsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CalendarMonthLogsProvider && other.month == month;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, month.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CalendarMonthLogsRef
    on AutoDisposeFutureProviderRef<Map<DateTime, CycleDayLog>> {
  /// The parameter `month` of this provider.
  DateTime get month;
}

class _CalendarMonthLogsProviderElement
    extends AutoDisposeFutureProviderElement<Map<DateTime, CycleDayLog>>
    with CalendarMonthLogsRef {
  _CalendarMonthLogsProviderElement(super.provider);

  @override
  DateTime get month => (origin as CalendarMonthLogsProvider).month;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
