import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inner_flare/core/providers/quick_stat_preferences_provider.dart';
import 'package:inner_flare/models/quick_stat.dart';

/// Lets the user independently choose each quick stat slot's stat type,
/// and — for a slot showing "days since last period" — which point in the
/// period it counts from (docs/features/quick_stats.feature). Both slots
/// are allowed to show the same stat type; neither is mandatory to differ
/// from the other.
class QuickStatCustomizeScreen extends ConsumerWidget {
  const QuickStatCustomizeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(quickStatPreferencesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Customize quick stats')),
      body: prefsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Couldn\'t load: $error')),
        data: (prefs) {
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              for (final pref in prefs) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                  child: Text(
                    'Slot ${pref.slot + 1}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                RadioGroup<QuickStatType>(
                  groupValue: pref.type,
                  onChanged: (type) {
                    if (type == null) return;
                    ref
                        .read(quickStatPreferencesProvider.notifier)
                        .setType(pref.slot, type);
                  },
                  child: Column(
                    children: [
                      for (final type in QuickStatType.values)
                        RadioListTile<QuickStatType>(
                          key: ValueKey(
                            'quick-stat-slot-${pref.slot}-type-${type.name}',
                          ),
                          title: Text(type.label),
                          value: type,
                        ),
                    ],
                  ),
                ),
                if (pref.type == QuickStatType.daysSinceLastPeriod)
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: RadioGroup<QuickStatReferencePoint>(
                      groupValue: pref.referencePoint,
                      onChanged: (point) {
                        if (point == null) return;
                        ref
                            .read(quickStatPreferencesProvider.notifier)
                            .setReferencePoint(pref.slot, point);
                      },
                      child: Column(
                        children: [
                          for (final point in QuickStatReferencePoint.values)
                            RadioListTile<QuickStatReferencePoint>(
                              key: ValueKey(
                                'quick-stat-slot-${pref.slot}-refpoint-'
                                '${point.name}',
                              ),
                              title: Text(point.label),
                              value: point,
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}
