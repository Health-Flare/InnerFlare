import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inner_flare/core/providers/cycle_insights_provider.dart';
import 'package:inner_flare/core/theme/app_theme.dart';
import 'package:inner_flare/features/insights/widgets/insight_stat_card.dart';

const _monthAbbreviations = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _formatDate(DateTime date) {
  return '${_monthAbbreviations[date.month - 1]} ${date.day}';
}

String _formatRange(DateTime start, DateTime end) {
  return start.month == end.month && start.year == end.year
      ? '${_formatDate(start)} – ${end.day}'
      : '${_formatDate(start)} – ${_formatDate(end)}';
}

/// Cycle insights and predictions (docs/features/insights.feature): average
/// cycle length, variability, and predicted next period/fertile window,
/// all recomputed live from logged period starts — nothing is cached, so
/// editing a past entry is reflected the next time this screen builds.
///
/// Not a medical device — predictions here are plain statistics over the
/// user's own logged dates, always shown with what they're based on, never
/// as an opaque forecast (see CLAUDE.md, "Privacy-Centric").
class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insights = ref.watch(cycleInsightsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: SafeArea(
        child: switch (insights) {
          AsyncData(:final value) => _InsightsBody(insights: value),
          AsyncError() => const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: Text("Couldn't load your insights.")),
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

class _InsightsBody extends StatelessWidget {
  const _InsightsBody({required this.insights});

  final CycleInsights insights;

  @override
  Widget build(BuildContext context) {
    if (insights.hasNoHistory) {
      return _EmptyState(
        icon: Icons.insights_rounded,
        title: 'Not enough data yet',
        message:
            'Log your next period start and this screen will begin showing '
            'estimates — nothing is guessed in the meantime.',
      );
    }

    if (insights.needsSecondCycle) {
      return _EmptyState(
        icon: Icons.hourglass_top_rounded,
        title: 'One cycle logged',
        message:
            'A cycle length needs two period starts to measure. Log your '
            'next one and average cycle length will show up here.',
      );
    }

    final average = insights.averageCycleLength!;
    final cyclesUsed = insights.cycleLengths.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      children: [
        InsightStatCard(
          icon: Icons.autorenew_rounded,
          title: 'Average cycle length',
          value: '${average.round()} days',
          caveat: insights.isIrregular
              ? 'Based on your last $cyclesUsed cycle${cyclesUsed == 1 ? '' : 's'}. '
                    "These have varied by more than a week — treat this as "
                    'a rough guide, not a fixed rule.'
              : 'Based on your last $cyclesUsed cycle${cyclesUsed == 1 ? '' : 's'}.',
        ),
        if (insights.hasVariabilityData) ...[
          const SizedBox(height: 12),
          InsightStatCard(
            icon: Icons.show_chart_rounded,
            title: 'Cycle variability',
            value: '± ${insights.variability!.round()} days',
            caveat:
                'How much your recent cycle lengths differ from the '
                'average — higher means less predictable timing.',
          ),
        ],
        if (insights.periodRange != null) ...[
          const SizedBox(height: 12),
          InsightStatCard(
            icon: Icons.water_drop_rounded,
            title: 'Predicted next period',
            value: _formatRange(
              insights.periodRange!.start,
              insights.periodRange!.end,
            ),
            caveat: 'An estimate based on your average cycle length.',
          ),
        ],
        if (insights.fertileWindow != null) ...[
          const SizedBox(height: 12),
          InsightStatCard(
            icon: Icons.favorite_rounded,
            title: 'Predicted fertile window',
            value: _formatRange(
              insights.fertileWindow!.start,
              insights.fertileWindow!.end,
            ),
            caveat: 'An estimate — not a reliable method of contraception.',
          ),
        ],
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.emberOrange),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.deepTeal.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
