import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inner_flare/core/debug/demo_data.dart';
import 'package:inner_flare/core/providers/cycle_day_log_repository_provider.dart';
import 'package:inner_flare/core/providers/database_provider.dart';
import 'package:inner_flare/core/providers/lock_timeout_provider.dart';
import 'package:inner_flare/core/providers/log_data_invalidation.dart';
import 'package:inner_flare/core/providers/now_provider.dart';
import 'package:inner_flare/features/dashboard/widgets/database_status_indicator.dart';
import 'package:inner_flare/features/export/screens/export_screen.dart';
import 'package:inner_flare/features/export/screens/import_screen.dart';
import 'package:inner_flare/features/settings/screens/auto_lock_settings_screen.dart';
import 'package:inner_flare/features/settings/screens/symptom_settings_screen.dart';
import 'package:inner_flare/models/cycle_day_log.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// App settings (docs/features/navigation.feature: "Settings is reachable
/// without leaving the current task"). Currently the encrypted database's
/// connection status (a diagnostic aid for real-device unlock issues,
/// see lib/core/security/biometric_gate.dart), the idle-lock timeout
/// (docs/features/app_lock.feature, on its own page), and the symptom catalog
/// (docs/features/symptom_settings.feature), more settings land here as
/// they're built.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watched directly, independent of the auto-lock section below: if the
    // database is locked, lockTimeoutProvider (which reads a setting out of
    // that same database) will be in an error state too, and the database
    // status, with its Unlock action, must still render regardless.
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
              'Security',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            title: const Text('Auto-lock'),
            subtitle: Text(
              lockTimeoutAsync.when(
                loading: () => 'Loading…',
                error: (_, _) => "Couldn't load",
                data: (current) => current.label,
              ),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AutoLockSettingsScreen(),
                ),
              );
            },
          ),
          const Divider(height: 32),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Text(
              'Symptoms',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            title: const Text('Symptoms to track'),
            subtitle: const Text(
              'Change, add, enable, or disable the symptoms you can log.',
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SymptomSettingsScreen(),
                ),
              );
            },
          ),
          const Divider(height: 32),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Text(
              'Backup',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            title: const Text('Export data'),
            subtitle: const Text(
              'Save a backup file to move to your own other device.',
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ExportScreen()));
            },
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            title: const Text('Import data'),
            subtitle: const Text('Restore a previously exported backup file.'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ImportScreen()));
            },
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
                'Debug builds only, never shipped to users: fills the log '
                'with sample history. The regular set is a few months of '
                'steady cycles for taking screenshots; the perimenopause '
                'set is eight months of shifting cycle lengths, varying '
                'flow and hot-flash/sleep symptoms for exercising the '
                'irregular-cycle handling. Loading one over the other '
                'overwrites any day they share.',
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: OutlinedButton(
                onPressed: () =>
                    _loadDemoData(context, ref, buildDemoCycleLogs),
                child: const Text('Load demo data'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: OutlinedButton(
                onPressed: () => _loadDemoData(
                  context,
                  ref,
                  buildPerimenopauseDemoCycleLogs,
                ),
                child: const Text('Load perimenopause demo data'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Fills the log with the dataset [buildLogs] generates (see
/// lib/core/debug/demo_data.dart) via the same repository real logging
/// goes through, then invalidates every provider that reads from it so
/// the dashboard/calendar/insights screens reflect it immediately.
/// Debug-only, see the "Demo data" section above.
Future<void> _loadDemoData(
  BuildContext context,
  WidgetRef ref,
  List<CycleDayLog> Function({required DateTime now}) buildLogs,
) async {
  final repository = await ref.read(cycleDayLogRepositoryProvider.future);
  final now = ref.read(nowProvider)();
  final logs = buildLogs(now: now)..sort((a, b) => a.date.compareTo(b.date));
  for (final log in logs) {
    await repository.save(log);
  }

  invalidateLogDependentProviders(ref);

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
      // A static icon, not a spinner, see the comment on the loading
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
