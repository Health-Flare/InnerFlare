import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inner_flare/core/debug/debug_chrome.dart';
import 'package:inner_flare/core/nudges/dashboard_nudges.dart';
import 'package:inner_flare/core/nudges/nudge_rules.dart';
import 'package:inner_flare/core/providers/nudge_state_provider.dart';

/// Debug builds only: every dashboard nudge with its stored state, plus
/// "End snoozes now" and "Reset all nudges", for testing nudges by hand in
/// the simulator (docs/features/dashboard_nudges.feature, "Debug builds can
/// reset and inspect nudges"). Settings shows it only when
/// [shownInSettings] is true.
class NudgeDebugSection extends ConsumerWidget {
  const NudgeDebugSection({super.key});

  /// Same switch as the Database and Demo data sections: off in release,
  /// TestFlight and screenshot builds.
  static const bool shownInSettings = showDebugChrome;

  static String describe(NudgeState? state) {
    if (state == null) return 'Never acted on';
    switch (state.disposition) {
      case NudgeDisposition.dismissedPermanently:
        return 'Dismissed';
      case NudgeDisposition.snoozedUntilCardAdded:
        return 'Snoozed until a card is added';
      case NudgeDisposition.snoozed:
        final d = state.snoozedUntil!;
        final mm = d.month.toString().padLeft(2, '0');
        final dd = d.day.toString().padLeft(2, '0');
        return 'Snoozed until ${d.year}-$mm-$dd';
    }
  }

  static String _name(DashboardNudge nudge) => switch (nudge) {
    DashboardNudge.cleanup => 'Dashboard cleanup',
    DashboardNudge.suggestGauge => 'Suggest a gauge card',
    DashboardNudge.suggestTrend => 'Suggest a trend chart',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final states = ref.watch(nudgeStatesProvider).value ?? const {};
    final notifier = ref.read(nudgeStatesProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 4),
          child: Text('Nudges', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Text(
            'Debug builds only. Each dashboard nudge and what you last did '
            'about it. Reset to see them again from scratch.',
          ),
        ),
        for (final nudge in DashboardNudge.values)
          ListTile(
            dense: true,
            title: Text(_name(nudge)),
            subtitle: Text(describe(states[nudge])),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: OutlinedButton(
            onPressed: notifier.endAllSnoozes,
            child: const Text('End snoozes now'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: OutlinedButton(
            onPressed: notifier.resetAll,
            child: const Text('Reset all nudges'),
          ),
        ),
      ],
    );
  }
}
