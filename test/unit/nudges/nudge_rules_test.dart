// Exercises docs/features/dashboard_nudges.feature against the pure
// nudge-rules module. No Flutter, no database — see
// lib/core/nudges/nudge_rules.dart.

import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/core/nudges/nudge_rules.dart';

void main() {
  group('shouldShowNudge', () {
    test('a nudge with no persisted state shows', () {
      expect(
        shouldShowNudge(state: null, now: DateTime.utc(2026, 1, 1)),
        isTrue,
      );
    });

    test('a permanently-dismissed nudge never shows again', () {
      final state = const NudgeState(
        disposition: NudgeDisposition.dismissedPermanently,
      );
      expect(
        shouldShowNudge(state: state, now: DateTime.utc(2026, 1, 1)),
        isFalse,
      );
      expect(
        shouldShowNudge(state: state, now: DateTime.utc(2099, 1, 1)),
        isFalse,
      );
    });

    test('a snoozed nudge stays hidden until its snooze date', () {
      final state = NudgeState(
        disposition: NudgeDisposition.snoozed,
        snoozedUntil: DateTime.utc(2026, 2, 1),
      );
      expect(
        shouldShowNudge(state: state, now: DateTime.utc(2026, 1, 15)),
        isFalse,
      );
    });

    test('a snoozed nudge shows again once the snooze date is reached', () {
      final state = NudgeState(
        disposition: NudgeDisposition.snoozed,
        snoozedUntil: DateTime.utc(2026, 2, 1),
      );
      expect(
        shouldShowNudge(state: state, now: DateTime.utc(2026, 2, 1)),
        isTrue,
      );
      expect(
        shouldShowNudge(state: state, now: DateTime.utc(2026, 3, 1)),
        isTrue,
      );
    });

    test(
      'constructing a snoozed state without a snoozedUntil date asserts',
      () {
        expect(
          () => NudgeState(disposition: NudgeDisposition.snoozed),
          throwsA(isA<AssertionError>()),
        );
      },
    );
  });

  // docs/features/dashboard_nudges.feature, "Snoozing a suggestion nudge
  // re-surfaces after roughly two cycles" / "...before any cycle history
  // exists".
  group('suggestionNudgeSnoozeUntil', () {
    test('twice the user\'s own average cycle length', () {
      final until = suggestionNudgeSnoozeUntil(
        now: DateTime.utc(2026, 1, 1),
        averageCycleLength: 30,
      );
      expect(until, DateTime.utc(2026, 3, 2)); // 60 days after Jan 1
    });

    test('falls back to twice the standard clinical estimate with no '
        'average yet', () {
      final until = suggestionNudgeSnoozeUntil(
        now: DateTime.utc(2026, 1, 1),
        averageCycleLength: null,
      );
      expect(until, DateTime.utc(2026, 2, 26)); // 56 days after Jan 1
    });

    test('rounds a fractional average cycle length to a whole day count', () {
      final until = suggestionNudgeSnoozeUntil(
        now: DateTime.utc(2026, 1, 1),
        averageCycleLength: 28.6,
      );
      // 2 * 28.6 = 57.2, rounds to 57 days.
      expect(until, DateTime.utc(2026, 2, 27));
    });

    test('is DST-safe, per the same dateOnly rule cycle_math uses '
        'elsewhere', () {
      // Crosses the US spring-forward transition (2026-03-08); a naive
      // local-time calculation could land a day off.
      final until = suggestionNudgeSnoozeUntil(
        now: DateTime(2026, 2, 1),
        averageCycleLength: 28,
      );
      expect(until, DateTime.utc(2026, 3, 29));
    });
  });
}
