import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inner_flare/core/cycle_math/cycle_math.dart'
    show CycleDetailRow;
import 'package:inner_flare/core/providers/cycle_detail_rows_provider.dart';
import 'package:inner_flare/core/theme/app_theme.dart';

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
  return '${_monthAbbreviations[date.month - 1]} ${date.day}, ${date.year}';
}

/// A cycle-by-cycle table — length and the gap versus the cycle before it
/// — reachable from both the "previous cycle lengths" and "cycle length
/// variability" trend cards (docs/features/dashboard_visualizations
/// .feature, "The cycle detail table lists every complete cycle...").
/// Meant to be quick to review, e.g. ahead of or during a conversation
/// with a healthcare provider — see "The cycle detail table makes no
/// diagnostic claim": this screen states only what was logged, nothing
/// interpreted or diagnosed.
class CycleDetailScreen extends ConsumerWidget {
  const CycleDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rowsAsync = ref.watch(cycleDetailRowsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Cycle history')),
      body: rowsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Couldn\'t load: $error')),
        data: (rows) => _CycleDetailList(rows: rows),
      ),
    );
  }
}

class _CycleDetailList extends StatelessWidget {
  const _CycleDetailList({required this.rows});

  final List<CycleDetailRow> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Not enough cycles logged yet — this fills in once you have '
            'at least one complete cycle.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      itemCount: rows.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              'A record of what you\'ve logged — not a diagnosis or '
              'medical assessment. Most recent cycle first.',
            ),
          );
        }
        if (index == rows.length + 1) {
          return const SizedBox(height: 8);
        }

        final row = rows[index - 1];
        final diff = row.differenceFromPreviousDays;
        final diffText = diff == null
            ? 'first cycle on record'
            : diff == 0
            ? 'same as the cycle before'
            : '${diff > 0 ? '+' : ''}$diff days vs. the cycle before';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.emberOrange.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDate(row.start),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(diffText, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              Text(
                '${row.lengthDays} days',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      },
    );
  }
}
