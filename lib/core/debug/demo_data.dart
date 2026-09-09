import 'package:inner_flare/models/cycle_day_log.dart';
import 'package:inner_flare/models/ovulation_test_result.dart';
import 'package:inner_flare/models/period_flow.dart';
import 'package:inner_flare/models/symptom.dart';

/// A deterministic set of [CycleDayLog]s used only to populate the app
/// with realistic-looking history for taking app-store screenshots (see
/// lib/features/settings/screens/settings_screen.dart, "Demo data" —
/// debug builds only, never shipped). Pure and driven entirely by [now],
/// same rule as lib/core/cycle_math/cycle_math.dart, so the generated
/// history always ends near "today" no matter when this runs, and never
/// logs a date in the future.
///
/// The persona behind this dataset, for anyone reading a store
/// screenshot or this file later, is "Jane Doe" — a placeholder name
/// used only in our own screenshot tooling and its documentation.
/// InnerFlare itself has no name/profile field anywhere (no accounts,
/// per CLAUDE.md's "Privacy-Centric" — see docs/features/onboarding.
/// feature), so nothing here writes that name into the app or its data.
///
/// Six period starts (five complete cycles, 27-30 days each — irregular
/// enough to be believable, not so irregular it trips the "irregular
/// cycles" caveat) ending 6 days ago, so "today" and yesterday are still
/// unlogged on a fresh install of the demo data. Each complete cycle gets
/// a realistic 5-day period taper, an ovulation-test/basal-temp pair, and
/// a couple of PMS-adjacent symptom days; the most recent (in-progress)
/// cycle only gets the period days that have actually happened so far.
List<CycleDayLog> buildDemoCycleLogs({required DateTime now}) {
  final today = DateTime.utc(now.year, now.month, now.day);

  // Gaps between consecutive period starts, oldest pair first.
  const cycleLengths = [28, 27, 29, 28, 30];

  // Days-before-today for each period start, oldest first, ending with
  // the most recent start 6 days ago.
  final periodStartOffsets = <int>[];
  var offset = 6;
  for (final length in cycleLengths.reversed) {
    periodStartOffsets.add(offset);
    offset += length;
  }
  periodStartOffsets.add(offset);
  final oldestFirst = periodStartOffsets.reversed.toList();

  final logs = <CycleDayLog>[];
  for (var i = 0; i < oldestFirst.length; i++) {
    final startDate = today.subtract(Duration(days: oldestFirst[i]));
    final isMostRecent = i == oldestFirst.length - 1;
    logs.addAll(_periodDays(startDate, today: today));
    if (!isMostRecent) {
      logs.addAll(_midCycleDays(startDate));
    }
  }

  return logs;
}

/// A 5-day period with a realistic flow taper: medium, heavy, heavy,
/// light, spotting. Truncated at [today] so the in-progress cycle never
/// logs a future day.
List<CycleDayLog> _periodDays(DateTime startDate, {required DateTime today}) {
  const flows = [
    PeriodFlow.medium,
    PeriodFlow.heavy,
    PeriodFlow.heavy,
    PeriodFlow.light,
    PeriodFlow.spotting,
  ];
  return [
    for (var day = 0; day < flows.length; day++)
      if (!startDate.add(Duration(days: day)).isAfter(today))
        CycleDayLog(
          date: startDate.add(Duration(days: day)),
          periodFlow: flows[day],
          symptoms: day == 0
              ? const {Symptom.cramps, Symptom.fatigue}
              : day == 1
              ? const {Symptom.cramps}
              : const {},
          note: day == 0 ? 'Cramps started overnight, first day today.' : null,
        ),
  ];
}

/// A few logged days between periods: an ovulation-test pair mid-cycle
/// and PMS-adjacent symptoms shortly before the next period, so the
/// calendar and log history look like they came from actual use rather
/// than a batch import. Only ever called for a cycle that has fully
/// completed, so every offset here is safely in the past.
List<CycleDayLog> _midCycleDays(DateTime periodStartDate) {
  return [
    CycleDayLog(
      date: periodStartDate.add(const Duration(days: 13)),
      ovulationTestResult: OvulationTestResult.negative,
      basalBodyTempCelsius: 36.4,
    ),
    CycleDayLog(
      date: periodStartDate.add(const Duration(days: 14)),
      ovulationTestResult: OvulationTestResult.positive,
      basalBodyTempCelsius: 36.7,
      symptoms: const {Symptom.tenderBreasts},
    ),
    CycleDayLog(
      date: periodStartDate.add(const Duration(days: 22)),
      symptoms: const {Symptom.bloating, Symptom.moodSwings},
    ),
    CycleDayLog(
      date: periodStartDate.add(const Duration(days: 25)),
      symptoms: const {Symptom.headache, Symptom.fatigue},
      note: 'Low energy today, went to bed early.',
    ),
  ];
}
