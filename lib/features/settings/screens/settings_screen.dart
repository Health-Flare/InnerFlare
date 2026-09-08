import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inner_flare/core/providers/lock_timeout_provider.dart';
import 'package:inner_flare/models/lock_timeout.dart';

/// App settings (docs/features/navigation.feature: "Settings is reachable
/// without leaving the current task"). Currently just the idle-lock
/// timeout (docs/features/app_lock.feature) — more settings land here as
/// they're built.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lockTimeoutAsync = ref.watch(lockTimeoutProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: lockTimeoutAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text("Couldn't load settings: $error")),
        data: (current) => ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 4),
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
            RadioGroup<LockTimeout>(
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
          ],
        ),
      ),
    );
  }
}
