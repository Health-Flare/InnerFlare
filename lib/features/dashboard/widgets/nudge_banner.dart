import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inner_flare/core/nudges/dashboard_card_cleanup.dart';
import 'package:inner_flare/core/nudges/dashboard_nudges.dart';
import 'package:inner_flare/core/providers/dashboard_card_preferences_provider.dart';
import 'package:inner_flare/core/providers/nudge_state_provider.dart';
import 'package:inner_flare/core/theme/app_theme.dart';
import 'package:inner_flare/features/dashboard/screens/dashboard_customize_screen.dart';
import 'package:inner_flare/models/dashboard_card.dart';

/// The single dashboard nudge, if one applies (docs/features/
/// dashboard_nudges.feature). Sits between "Log today" and the card grid.
/// Every nudge has one button that does what it suggests, "Not now"
/// (snooze) and "Don't suggest this again" (dismiss).
class DashboardNudgeSlot extends ConsumerWidget {
  const DashboardNudgeSlot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nudge = ref.watch(currentDashboardNudgeProvider).value;
    final cards = ref.watch(dashboardCardPreferencesProvider).value;
    if (nudge == null || cards == null) return const SizedBox.shrink();

    final copy = _copyFor(nudge, cards);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: NudgeBanner(
        title: copy.title,
        body: copy.body,
        actionLabel: copy.actionLabel,
        onAction: () => _act(context, ref, nudge, cards),
        onNotNow: () => ref.read(nudgeStatesProvider.notifier).snooze(nudge),
        onDismiss: () => ref.read(nudgeStatesProvider.notifier).dismiss(nudge),
      ),
    );
  }

  Future<void> _act(
    BuildContext context,
    WidgetRef ref,
    DashboardNudge nudge,
    List<DashboardCardInstance> cards,
  ) async {
    final prefs = ref.read(dashboardCardPreferencesProvider.notifier);
    switch (nudge) {
      case DashboardNudge.suggestGauge:
        await prefs.addCard(newGaugeCardInstance(order: cards.length));
      case DashboardNudge.suggestTrend:
        await prefs.addCard(newTrendCardInstance(order: cards.length));
      case DashboardNudge.cleanup:
        final extras = extraDuplicateCardIds(cards);
        if (extras.isNotEmpty) {
          for (final id in extras) {
            await prefs.removeCard(id);
          }
          return;
        }
        if (!context.mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DashboardCustomizeScreen()),
        );
    }
  }

  _NudgeCopy _copyFor(DashboardNudge nudge, List<DashboardCardInstance> cards) {
    switch (nudge) {
      case DashboardNudge.suggestGauge:
        return const _NudgeCopy(
          title: 'Add a gauge card?',
          body:
              'It shows how far you are into your cycle at a glance, '
              'measured against your own cycle length.',
          actionLabel: 'Add gauge',
        );
      case DashboardNudge.suggestTrend:
        return const _NudgeCopy(
          title: 'Add a trend chart?',
          body:
              "You've logged enough cycles to compare them. A trend chart "
              'shows how their lengths have changed.',
          actionLabel: 'Add trend chart',
        );
      case DashboardNudge.cleanup:
        final groups = findDuplicateCardGroups(
          cards.where((c) => c.visible).toList(),
        );
        if (groups.isNotEmpty) {
          final names = groups.map((g) => _cardName(g.first)).join(', ');
          return _NudgeCopy(
            title: 'Some cards show the same thing',
            body: 'You have more than one $names card.',
            actionLabel: 'Remove extra',
          );
        }
        return const _NudgeCopy(
          title: 'Your dashboard is getting busy',
          body: 'Want to review which cards you still use?',
          actionLabel: 'Review',
        );
    }
  }

  static String _cardName(DashboardCardInstance card) => switch (card.kind) {
    DashboardCardKind.gauge => '"${card.gaugeMode.label}"',
    DashboardCardKind.trend => '"${card.trendMetric.label}"',
    _ => card.kind.label,
  };
}

class _NudgeCopy {
  const _NudgeCopy({
    required this.title,
    required this.body,
    required this.actionLabel,
  });

  final String title;
  final String body;
  final String actionLabel;
}

/// The banner itself: plain, no animation (an indeterminate animation
/// would stop widget tests settling, see CLAUDE.md).
class NudgeBanner extends StatelessWidget {
  const NudgeBanner({
    super.key,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
    required this.onNotNow,
    required this.onDismiss,
  });

  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;
  final VoidCallback onNotNow;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      label: 'Suggestion',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
        decoration: BoxDecoration(
          color: AppColors.softOrange.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                title,
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(body, style: text.bodyMedium),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              children: [
                FilledButton.tonal(
                  onPressed: onAction,
                  child: Text(actionLabel),
                ),
                TextButton(onPressed: onNotNow, child: const Text('Not now')),
                TextButton(
                  onPressed: onDismiss,
                  child: const Text("Don't suggest this again"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
