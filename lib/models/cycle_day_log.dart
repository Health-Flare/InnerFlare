import 'package:inner_flare/models/ovulation_test_result.dart';
import 'package:inner_flare/models/period_flow.dart';
import 'package:inner_flare/models/symptom.dart';

/// Domain model for a single logged day. Immutable; maps to the
/// `cycle_day_logs` table (see BRIEF.md §4.3) via a repository, never
/// used directly as a database row.
class CycleDayLog {
  const CycleDayLog({
    required this.date,
    this.periodFlow,
    this.isPeriodStart = false,
    this.symptoms = const {},
    this.note,
    this.ovulationTestResult,
    this.basalBodyTempCelsius,
  });

  /// Date-only (UTC midnight) so day arithmetic is never skewed by DST.
  final DateTime date;
  final PeriodFlow? periodFlow;
  final bool isPeriodStart;
  final Set<Symptom> symptoms;
  final String? note;
  final OvulationTestResult? ovulationTestResult;
  final double? basalBodyTempCelsius;

  CycleDayLog copyWith({
    DateTime? date,
    PeriodFlow? periodFlow,
    bool? isPeriodStart,
    Set<Symptom>? symptoms,
    String? note,
    OvulationTestResult? ovulationTestResult,
    double? basalBodyTempCelsius,
  }) {
    return CycleDayLog(
      date: date ?? this.date,
      periodFlow: periodFlow ?? this.periodFlow,
      isPeriodStart: isPeriodStart ?? this.isPeriodStart,
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
    Object.hashAllUnordered(symptoms),
    note,
    ovulationTestResult,
    basalBodyTempCelsius,
  );
}
