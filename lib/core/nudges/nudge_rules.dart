/// Pure rules for the "gently suggest, never nag" dashboard nudge
/// mechanism (docs/features/dashboard_nudges.feature). No Flutter, no
/// database — every "now" is passed in by the caller, matching
/// lib/core/cycle_math/cycle_math.dart's determinism rule, so this is
/// exhaustively unit-testable without a widget or a database.
///
/// This file only knows how to decide *whether* a nudge (identified
/// however the caller likes — a string id, an enum, whatever fits) should
/// currently show, given its persisted [NudgeState]. It has no opinion on
/// *which* nudges exist or what triggers them — those conditions live
/// with whatever feature defines them (see
/// docs/features/dashboard_visualizations.feature for the card-discovery
/// and cleanup nudges, docs/features/dashboard_presets.feature for bundle
/// suggestions).
library;

import 'package:inner_flare/core/cycle_math/cycle_math.dart'
    show dateOnly, defaultCycleLengthDays;

/// What the user last did about a nudge — absent (never acted on) is
/// represented by a null [NudgeState] wherever this is used, not by a
/// third enum value, so "never seen" and "seen but not acted on yet"
/// don't need to be distinguished by callers that don't care.
enum NudgeDisposition { dismissedPermanently, snoozed }

/// The persisted state of a single nudge. [snoozedUntil] is only
/// meaningful when [disposition] is [NudgeDisposition.snoozed]; a
/// permanently-dismissed nudge has no expiry.
class NudgeState {
  const NudgeState({required this.disposition, this.snoozedUntil})
    : assert(
        disposition != NudgeDisposition.snoozed || snoozedUntil != null,
        'a snoozed NudgeState must carry a snoozedUntil date',
      );

  final NudgeDisposition disposition;
  final DateTime? snoozedUntil;
}

/// Whether a nudge should show right now, given its persisted [state] (or
/// null if it has never been dismissed or snoozed). A dismissed nudge
/// never shows again, regardless of [now]. A snoozed nudge stays hidden
/// until [now] reaches its snooze date, then shows again (see "Every
/// nudge offers exactly two ways to act on it").
bool shouldShowNudge({required NudgeState? state, required DateTime now}) {
  if (state == null) return true;
  switch (state.disposition) {
    case NudgeDisposition.dismissedPermanently:
      return false;
    case NudgeDisposition.snoozed:
      return !now.isBefore(state.snoozedUntil!);
  }
}

/// The date a "suggestion" nudge (a card-suggestion or bundle-suggestion
/// nudge — anything snoozed for "roughly two cycles" rather than "until
/// the next card is added") should stay hidden until, given [now] and the
/// user's own [averageCycleLength]. Uses twice the user's own average, so
/// someone with longer cycles gets a proportionally longer snooze, never
/// a fixed day count. Falls back to twice the standard clinical estimate
/// when there's no personal average yet (see "Snoozing a suggestion
/// nudge before any cycle history exists").
DateTime suggestionNudgeSnoozeUntil({
  required DateTime now,
  required double? averageCycleLength,
}) {
  final cycleLength = averageCycleLength ?? defaultCycleLengthDays;
  final snoozeDays = (cycleLength * 2).round();
  return dateOnly(now).add(Duration(days: snoozeDays));
}
