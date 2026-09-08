// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cycle_day_log_entry_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$cycleDayLogEntryHash() => r'695ccb5522a889c6c9a895117f0524b6dabe4cb3';

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

abstract class _$CycleDayLogEntry
    extends BuildlessAutoDisposeAsyncNotifier<CycleDayLog?> {
  late final DateTime date;

  FutureOr<CycleDayLog?> build(DateTime date);
}

/// The saved entry (if any) for a single date — backs the log-entry
/// screen for today or any prior day (docs/features/log.feature,
/// "Back-logging a missed day is exactly as fast as logging today").
///
/// [date] must be date-only (no time-of-day component) so the same
/// calendar day always resolves to the same provider instance.
///
/// Copied from [CycleDayLogEntry].
@ProviderFor(CycleDayLogEntry)
const cycleDayLogEntryProvider = CycleDayLogEntryFamily();

/// The saved entry (if any) for a single date — backs the log-entry
/// screen for today or any prior day (docs/features/log.feature,
/// "Back-logging a missed day is exactly as fast as logging today").
///
/// [date] must be date-only (no time-of-day component) so the same
/// calendar day always resolves to the same provider instance.
///
/// Copied from [CycleDayLogEntry].
class CycleDayLogEntryFamily extends Family<AsyncValue<CycleDayLog?>> {
  /// The saved entry (if any) for a single date — backs the log-entry
  /// screen for today or any prior day (docs/features/log.feature,
  /// "Back-logging a missed day is exactly as fast as logging today").
  ///
  /// [date] must be date-only (no time-of-day component) so the same
  /// calendar day always resolves to the same provider instance.
  ///
  /// Copied from [CycleDayLogEntry].
  const CycleDayLogEntryFamily();

  /// The saved entry (if any) for a single date — backs the log-entry
  /// screen for today or any prior day (docs/features/log.feature,
  /// "Back-logging a missed day is exactly as fast as logging today").
  ///
  /// [date] must be date-only (no time-of-day component) so the same
  /// calendar day always resolves to the same provider instance.
  ///
  /// Copied from [CycleDayLogEntry].
  CycleDayLogEntryProvider call(DateTime date) {
    return CycleDayLogEntryProvider(date);
  }

  @override
  CycleDayLogEntryProvider getProviderOverride(
    covariant CycleDayLogEntryProvider provider,
  ) {
    return call(provider.date);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'cycleDayLogEntryProvider';
}

/// The saved entry (if any) for a single date — backs the log-entry
/// screen for today or any prior day (docs/features/log.feature,
/// "Back-logging a missed day is exactly as fast as logging today").
///
/// [date] must be date-only (no time-of-day component) so the same
/// calendar day always resolves to the same provider instance.
///
/// Copied from [CycleDayLogEntry].
class CycleDayLogEntryProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<CycleDayLogEntry, CycleDayLog?> {
  /// The saved entry (if any) for a single date — backs the log-entry
  /// screen for today or any prior day (docs/features/log.feature,
  /// "Back-logging a missed day is exactly as fast as logging today").
  ///
  /// [date] must be date-only (no time-of-day component) so the same
  /// calendar day always resolves to the same provider instance.
  ///
  /// Copied from [CycleDayLogEntry].
  CycleDayLogEntryProvider(DateTime date)
    : this._internal(
        () => CycleDayLogEntry()..date = date,
        from: cycleDayLogEntryProvider,
        name: r'cycleDayLogEntryProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$cycleDayLogEntryHash,
        dependencies: CycleDayLogEntryFamily._dependencies,
        allTransitiveDependencies:
            CycleDayLogEntryFamily._allTransitiveDependencies,
        date: date,
      );

  CycleDayLogEntryProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.date,
  }) : super.internal();

  final DateTime date;

  @override
  FutureOr<CycleDayLog?> runNotifierBuild(covariant CycleDayLogEntry notifier) {
    return notifier.build(date);
  }

  @override
  Override overrideWith(CycleDayLogEntry Function() create) {
    return ProviderOverride(
      origin: this,
      override: CycleDayLogEntryProvider._internal(
        () => create()..date = date,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        date: date,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<CycleDayLogEntry, CycleDayLog?>
  createElement() {
    return _CycleDayLogEntryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CycleDayLogEntryProvider && other.date == date;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, date.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CycleDayLogEntryRef on AutoDisposeAsyncNotifierProviderRef<CycleDayLog?> {
  /// The parameter `date` of this provider.
  DateTime get date;
}

class _CycleDayLogEntryProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<CycleDayLogEntry, CycleDayLog?>
    with CycleDayLogEntryRef {
  _CycleDayLogEntryProviderElement(super.provider);

  @override
  DateTime get date => (origin as CycleDayLogEntryProvider).date;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
