import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inner_flare/core/providers/database_provider.dart';
import 'package:inner_flare/core/providers/lock_timeout_provider.dart';
import 'package:inner_flare/features/dashboard/widgets/database_status_indicator.dart';
import 'package:inner_flare/features/settings/screens/symptom_settings_screen.dart';
import 'package:inner_flare/models/lock_timeout.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// App settings (docs/features/navigation.feature: "Settings is reachable
/// without leaving the current task"). Currently the encrypted database's
/// connection status (a diagnostic aid for real-device unlock issues —
/// see lib/core/security/biometric_gate.dart), the idle-lock timeout
/// (docs/features/app_lock.feature), and the symptom catalog
/// (docs/features/symptom_settings.feature) — more settings land here as
/// they're built.
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
              'How long InnerFlare can sit in the background before you '
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
        ],
      ),
    );
  }
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
