import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inner_flare/core/debug/demo_data.dart';
import 'package:inner_flare/core/providers/calendar_month_logs_provider.dart';
import 'package:inner_flare/core/providers/cycle_day_log_entry_provider.dart';
import 'package:inner_flare/core/providers/cycle_day_log_repository_provider.dart';
import 'package:inner_flare/core/providers/cycle_insights_provider.dart';
import 'package:inner_flare/core/providers/cycle_prediction_provider.dart';
import 'package:inner_flare/core/providers/database_provider.dart';
import 'package:inner_flare/core/providers/has_any_logs_provider.dart';
import 'package:inner_flare/core/providers/lock_timeout_provider.dart';
import 'package:inner_flare/core/providers/now_provider.dart';
import 'package:inner_flare/core/providers/today_log_provider.dart';
import 'package:inner_flare/features/dashboard/widgets/database_status_indicator.dart';
import 'package:inner_flare/models/lock_timeout.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// App settings (docs/features/navigation.feature: "Settings is reachable
/// without leaving the current task"). Currently the encrypted database's
/// connection status (a diagnostic aid for real-device unlock issues —
/// see lib/core/security/biometric_gate.dart) and the idle-lock timeout
/// (docs/features/app_lock.feature) — more settings land here as they're
/// built.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watched directly, independent of the auto-lock section below: if the
    // database is locked, lockTimeoutProvider (which reads a setting out of
    // that same database) will be in an error state too, and the database
    // status — with its Unlock action — must still render regardless.
    final dbAsync = ref.watch(appDatabaseProvider);
    final lockTimeoutAsync = ref.watch(lockTimeoutProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Text(
              'Database',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: _DatabaseStatus(dbAsync: dbAsync),
          ),
          const Divider(height: 32),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Text(
              'Auto-lock',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              'How long Inner Flare can sit in the background before you '
              'need to unlock it again.',
            ),
          ),
          lockTimeoutAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text("Couldn't load: $error"),
            ),
            data: (current) => RadioGroup<LockTimeout>(
              groupValue: current,
              onChanged: (value) {
                if (value != null) {
                  ref.read(lockTimeoutProvider.notifier).setLockTimeout(value);
                }
              },
              child: Column(
                children: [
                  for (final timeout in LockTimeout.values)
                    RadioListTile<LockTimeout>(
                      title: Text(timeout.label),
                      value: timeout,
                    ),
                ],
              ),
            ),
          ),
          const Divider(height: 32),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Text('About', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ListTile(
            title: const Text('Open source licenses'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'Inner Flare',
            ),
          ),
          if (kDebugMode) ...[
            const Divider(height: 32),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 4),
              child: Text(
                'Demo data',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Debug builds only, never shipped to users — fills the log '
                'with a few months of sample history for taking '
                'screenshots.',
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: OutlinedButton(
                onPressed: () => _loadDemoData(context, ref),
                child: const Text('Load demo data'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Fills the log with [buildDemoCycleLogs] via the same repository real
/// logging goes through, then invalidates every provider that reads from
/// it so the dashboard/calendar/insights screens reflect it immediately.
/// Debug-only — see the "Demo data" section above.
Future<void> _loadDemoData(BuildContext context, WidgetRef ref) async {
  final repository = await ref.read(cycleDayLogRepositoryProvider.future);
  final now = ref.read(nowProvider)();
  final logs = buildDemoCycleLogs(now: now)
    ..sort((a, b) => a.date.compareTo(b.date));
  for (final log in logs) {
    await repository.save(log);
  }

  ref.invalidate(todayLogProvider);
  ref.invalidate(hasAnyLogsProvider);
  ref.invalidate(cycleInsightsProvider);
  ref.invalidate(cyclePredictionProvider);
  ref.invalidate(calendarMonthLogsProvider);
  ref.invalidate(cycleDayLogEntryProvider);

  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(const SnackBar(content: Text('Demo data loaded.')));
}

/// The database connection's current state, in full: a status line, the
/// raw error (selectable, so it can be copied while debugging a real
/// device) if locked, and a manual Unlock action.
class _DatabaseStatus extends ConsumerWidget {
  const _DatabaseStatus({required this.dbAsync});

  final AsyncValue<Database> dbAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return dbAsync.when(
      // A static icon, not a spinner — see the comment on the loading
      // branch of DatabaseStatusIndicator for why.
      loading: () => const Row(
        children: [
          Icon(Icons.hourglass_empty_rounded, size: 18),
          SizedBox(width: 8),
          Text('Checking…'),
        ],
      ),
      error: (error, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lock_rounded,
                color: Theme.of(context).colorScheme.error,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text('Locked'),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            error.toString(),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => retryDatabaseUnlock(ref),
            child: const Text('Unlock'),
          ),
        ],
      ),
      data: (_) => const Row(
        children: [
          Icon(Icons.lock_open_rounded, color: Colors.green, size: 18),
          SizedBox(width: 8),
          Text('Unlocked'),
        ],
      ),
    );
  }
}
