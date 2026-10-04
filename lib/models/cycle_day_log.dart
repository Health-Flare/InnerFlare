import 'package:inner_flare/models/ovulation_test_result.dart';
import 'package:inner_flare/models/period_flow.dart';

/// Domain model for a single logged day. Immutable; maps to the
/// `cycle_day_logs` table (see BRIEF.md §4.3) via a repository, never
/// used directly as a database row.
class CycleDayLog {
  const CycleDayLog({
    required this.date,
    this.periodFlow,
    this.isPeriodStart = false,
    this.periodDayOverride,
    this.isPeriodDay = false,
    this.symptoms = const {},
    this.note,
    this.ovulationTestResult,
    this.basalBodyTempCelsius,
  });

  /// Date-only (UTC midnight) so day arithmetic is never skewed by DST.
  final DateTime date;
  final PeriodFlow? periodFlow;
  final bool isPeriodStart;

  /// The user's own say on whether this day is a period day (issue #103):
  /// true = it is (and can start a period, whatever flow is logged),
  /// false = it isn't (left out of cycle maths, flow kept), null = work it
  /// out from flow. Stored. A choice that matches what flow alone would
  /// give is stored as null; see `normalisePeriodDayOverride`.
  final bool? periodDayOverride;

  /// Whether this day counts as part of a period once the whole log and
  /// every [periodDayOverride] are taken into account. Worked out on read,
  /// like [isPeriodStart]; never stored.
  final bool isPeriodDay;

  /// [TrackedSymptom.id] values (see lib/models/tracked_symptom.dart), not
  /// the symptoms themselves: a day's log outlives any later rename or
  /// disabling of the symptom it references.
  final Set<String> symptoms;
  final String? note;
  final OvulationTestResult? ovulationTestResult;
  final double? basalBodyTempCelsius;

  static const Object _unset = Object();

  /// [periodDayOverride] takes `null` to clear the choice; leave it out to
  /// keep the current one.
  CycleDayLog copyWith({
    DateTime? date,
    PeriodFlow? periodFlow,
    bool? isPeriodStart,
    Object? periodDayOverride = _unset,
    bool? isPeriodDay,
    Set<String>? symptoms,
    String? note,
    OvulationTestResult? ovulationTestResult,
    double? basalBodyTempCelsius,
  }) {
    return CycleDayLog(
      date: date ?? this.date,
      periodFlow: periodFlow ?? this.periodFlow,
      isPeriodStart: isPeriodStart ?? this.isPeriodStart,
      periodDayOverride: identical(periodDayOverride, _unset)
          ? this.periodDayOverride
          : periodDayOverride as bool?,
      isPeriodDay: isPeriodDay ?? this.isPeriodDay,
      symptoms: symptoms ?? this.symptoms,
      note: note ?? this.note,
      ovulationTestResult: ovulationTestResult ?? this.ovulationTestResult,
      basalBodyTempCelsius: basalBodyTempCelsius ?? this.basalBodyTempCelsius,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CycleDayLog &&
        other.date == date &&
        other.periodFlow == periodFlow &&
        other.isPeriodStart == isPeriodStart &&
        other.periodDayOverride == periodDayOverride &&
        other.isPeriodDay == isPeriodDay &&
        other.symptoms.length == symptoms.length &&
        other.symptoms.containsAll(symptoms) &&
        other.note == note &&
        other.ovulationTestResult == ovulationTestResult &&
        other.basalBodyTempCelsius == basalBodyTempCelsius;
  }

  @override
  int get hashCode => Object.hash(
    date,
    periodFlow,
    isPeriodStart,
    periodDayOverride,
    isPeriodDay,
    Object.hashAllUnordered(symptoms),
    note,
    ovulationTestResult,
    basalBodyTempCelsius,
  );
}
