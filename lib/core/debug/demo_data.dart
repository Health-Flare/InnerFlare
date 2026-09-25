import 'package:inner_flare/models/cycle_day_log.dart';
import 'package:inner_flare/models/ovulation_test_result.dart';
import 'package:inner_flare/models/period_flow.dart';

/// A deterministic set of [CycleDayLog]s used only to populate the app
/// with realistic-looking history for taking app-store screenshots (see
/// lib/features/settings/screens/settings_screen.dart, "Demo data",
/// debug builds only, never shipped). Pure and driven entirely by [now],
/// same rule as lib/core/cycle_math/cycle_math.dart, so the generated
/// history always ends near "today" no matter when this runs, and never
/// logs a date in the future.
///
/// The persona behind this dataset, for anyone reading a store
/// screenshot or this file later, is "Jane Doe", a placeholder name
/// used only in our own screenshot tooling and its documentation.
/// Inner Flare itself has no name/profile field anywhere (no accounts,
/// per CLAUDE.md's "Privacy-Centric", see docs/features/onboarding.
/// feature), so nothing here writes that name into the app or its data.
///
/// Six period starts (five complete cycles, 27-30 days each, irregular
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
  final starts = _periodStartDates(cycleLengths, today: today);

  final logs = <CycleDayLog>[];
  for (var i = 0; i < starts.length; i++) {
    final isMostRecent = i == starts.length - 1;
    logs.addAll(
      _periodDays(
        starts[i],
        today: today,
        flows: _regularPeriodFlows,
        firstDayNote: 'Cramps started overnight, first day today.',
      ),
    );
    if (!isMostRecent) {
      logs.addAll(_midCycleDays(starts[i]));
    }
  }

  return logs;
}

/// A second deterministic dataset, for exercising the app's irregular-cycle
/// handling: the history of someone entering perimenopause. Same contract
/// as [buildDemoCycleLogs] (pure, driven by [now], never logs a future
/// day, leaves today and yesterday unlogged).
///
/// Seven complete cycles that start out slightly short (24-26 days),
/// then drift: 31, 27, then a 45-day gap, a 35-day cycle and a 58-day
/// gap before the most recent (in-progress) period. Flow varies from
/// two-day spotting to nine days of heavy flow, ovulation tests stop
/// producing a clear positive as the gaps lengthen, and symptoms lean
/// toward sleep, mood and hot-flash complaints. The built-in symptom
/// list has no hot-flash or night-sweat entry, and this file must not
/// assume a custom symptom exists, so those ride in the day notes.
List<CycleDayLog> buildPerimenopauseDemoCycleLogs({required DateTime now}) {
  final today = DateTime.utc(now.year, now.month, now.day);

  // Oldest first; period i is the one that starts cycle i.
  const cycleLengths = [26, 24, 31, 27, 45, 35, 58];
  const periods = <List<PeriodFlow>>[
    _regularPeriodFlows,
    [PeriodFlow.heavy, PeriodFlow.heavy, PeriodFlow.medium, PeriodFlow.light],
    [
      PeriodFlow.medium,
      PeriodFlow.heavy,
      PeriodFlow.heavy,
      PeriodFlow.heavy,
      PeriodFlow.medium,
      PeriodFlow.light,
      PeriodFlow.spotting,
      PeriodFlow.spotting,
    ],
    [PeriodFlow.light, PeriodFlow.medium, PeriodFlow.light],
    [
      PeriodFlow.spotting,
      PeriodFlow.light,
      PeriodFlow.light,
      PeriodFlow.medium,
      PeriodFlow.heavy,
      PeriodFlow.heavy,
      PeriodFlow.heavy,
      PeriodFlow.medium,
      PeriodFlow.light,
    ],
    [PeriodFlow.spotting, PeriodFlow.light],
    [
      PeriodFlow.heavy,
      PeriodFlow.heavy,
      PeriodFlow.medium,
      PeriodFlow.medium,
      PeriodFlow.light,
      PeriodFlow.spotting,
    ],
    // The in-progress period starts 6 days ago, so five days here is the
    // most that leaves today and yesterday unlogged.
    [
      PeriodFlow.heavy,
      PeriodFlow.heavy,
      PeriodFlow.heavy,
      PeriodFlow.medium,
      PeriodFlow.medium,
    ],
  ];
  const firstDayNotes = <String?>[
    null,
    'Started a day early.',
    'Heavy, had to change every couple of hours.',
    'Barely a period this time.',
    'Two months since the last one, nearly stopped worrying about it.',
    'Just spotting, then nothing.',
    'Flooded through overnight. Almost 2 months since the last.',
    'Very heavy again, tired and dizzy.',
  ];

  final starts = _periodStartDates(cycleLengths, today: today);

  final logs = <CycleDayLog>[];
  for (var i = 0; i < starts.length; i++) {
    logs.addAll(
      _periodDays(
        starts[i],
        today: today,
        flows: periods[i],
        firstDayNote: firstDayNotes[i],
      ),
    );
    if (i < cycleLengths.length) {
      logs.addAll(
        _perimenopauseMidCycleDays(
          starts[i],
          cycleLength: cycleLengths[i],
          cycleIndex: i,
        ),
      );
    }
  }

  return logs;
}

/// The date of every period start, oldest first, given the gaps between
/// consecutive starts (oldest gap first). The most recent start is always
/// 6 days before [today], so "today" and yesterday are unlogged.
List<DateTime> _periodStartDates(
  List<int> cycleLengths, {
  required DateTime today,
}) {
  final offsets = <int>[];
  var offset = 6;
  for (final length in cycleLengths.reversed) {
    offsets.add(offset);
    offset += length;
  }
  offsets.add(offset);
  return [
    for (final daysAgo in offsets.reversed)
      today.subtract(Duration(days: daysAgo)),
  ];
}

const _regularPeriodFlows = [
  PeriodFlow.medium,
  PeriodFlow.heavy,
  PeriodFlow.heavy,
  PeriodFlow.light,
  PeriodFlow.spotting,
];

/// A period with the given [flows], one per day from [startDate].
/// Truncated at [today] so the in-progress cycle never logs a future day.
List<CycleDayLog> _periodDays(
  DateTime startDate, {
  required DateTime today,
  required List<PeriodFlow> flows,
  String? firstDayNote,
}) {
  return [
    for (var day = 0; day < flows.length; day++)
      if (!startDate.add(Duration(days: day)).isAfter(today))
        CycleDayLog(
          date: startDate.add(Duration(days: day)),
          periodFlow: flows[day],
          symptoms: day == 0
              ? const {'cramps', 'fatigue'}
              : day == 1
              ? const {'cramps'}
              : const {},
          note: day == 0 ? firstDayNote : null,
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
      symptoms: const {'tenderBreasts'},
    ),
    CycleDayLog(
      date: periodStartDate.add(const Duration(days: 22)),
      symptoms: const {'bloating', 'moodSwings'},
    ),
    CycleDayLog(
      date: periodStartDate.add(const Duration(days: 25)),
      symptoms: const {'headache', 'fatigue'},
      note: 'Low energy today, went to bed early.',
    ),
  ];
}

/// Logged days for one complete cycle of the perimenopause dataset.
/// Every offset is at least 10 (the longest period is nine days, so day
/// 10 is always clear of it) and at most `cycleLength - 2`, so it can
/// neither overlap this cycle's period nor touch the next period's first
/// day. An offset already used by an earlier entry is skipped, so a
/// date is never logged twice.
///
/// Early, still-ovulatory cycles get a negative/positive test pair;
/// later ones only ever test negative, at intervals, the way someone
/// keeps checking through a long cycle that never seems to peak.
List<CycleDayLog> _perimenopauseMidCycleDays(
  DateTime periodStartDate, {
  required int cycleLength,
  required int cycleIndex,
}) {
  final lastUsableOffset = cycleLength - 2;
  final logs = <CycleDayLog>[];
  final usedOffsets = <int>{};

  void add(int offset, CycleDayLog Function(DateTime date) build) {
    if (offset < 10 || offset > lastUsableOffset) return;
    if (!usedOffsets.add(offset)) return;
    logs.add(build(periodStartDate.add(Duration(days: offset))));
  }

  final ovulatory = cycleIndex <= 3 && cycleIndex != 2;
  if (ovulatory) {
    final ovulationOffset = cycleLength - 13;
    add(
      ovulationOffset - 1,
      (date) => CycleDayLog(
        date: date,
        ovulationTestResult: OvulationTestResult.negative,
        basalBodyTempCelsius: 36.4,
      ),
    );
    add(
      ovulationOffset,
      (date) => CycleDayLog(
        date: date,
        ovulationTestResult: OvulationTestResult.positive,
        basalBodyTempCelsius: 36.6,
      ),
    );
  } else {
    // Tested through the whole gap, never a clear positive, and a
    // temperature curve with no visible shift.
    for (var offset = 12; offset <= lastUsableOffset; offset += 7) {
      add(
        offset,
        (date) => CycleDayLog(
          date: date,
          ovulationTestResult: OvulationTestResult.negative,
          basalBodyTempCelsius: offset.isEven ? 36.3 : 36.5,
        ),
      );
    }
  }

  add(
    cycleLength - 8,
    (date) => CycleDayLog(
      date: date,
      symptoms: const {'fatigue', 'headache'},
      note: cycleIndex >= 4
          ? 'Night sweats again, soaked the sheets. Foggy all day.'
          : 'Slept badly, woke at 3am and could not get back to sleep.',
    ),
  );
  add(
    cycleLength - 4,
    (date) => CycleDayLog(
      date: date,
      symptoms: const {'moodSwings', 'bloating', 'tenderBreasts'},
      note: cycleIndex >= 2
          ? 'Hot flash in a meeting, then snapped at a friend.'
          : null,
    ),
  );
  if (cycleLength >= 40) {
    add(
      cycleLength ~/ 2,
      (date) => CycleDayLog(
        date: date,
        symptoms: const {'nausea', 'fatigue'},
        note: 'Woke up drenched. No idea where I am in my cycle any more.',
      ),
    );
  }

  return logs;
}
