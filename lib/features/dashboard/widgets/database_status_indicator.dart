import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inner_flare/core/providers/cycle_day_log_repository_provider.dart';
import 'package:inner_flare/core/providers/database_provider.dart';
import 'package:inner_flare/core/providers/today_log_provider.dart';

/// At-a-glance status of the encrypted database connection, with a manual
/// way to retry the biometric gate — a diagnostic aid for real-device
/// unlock issues (see the fail-open/fail-closed rules in
/// lib/core/security/biometric_gate.dart) until that's fully ironed out.
/// Shown in the dashboard's AppBar so it's visible without navigating
/// anywhere; the fuller picture (the actual error text) is in Settings.
class DatabaseStatusIndicator extends ConsumerWidget {
  const DatabaseStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbAsync = ref.watch(appDatabaseProvider);

    return dbAsync.when(
      // A static icon, not a spinner: this loading state is usually
      // instant, but it can also sit here indefinitely (e.g. a device
      // with no platform channel wired up), and an indeterminate
      // CircularProgressIndicator's animation never lets
      // WidgetTester.pumpAndSettle settle — see the widget tests here and
      // on DashboardScreen, none of which override appDatabaseProvider.
      loading: () => IconButton(
        tooltip: 'Checking database…',
        icon: const Icon(Icons.hourglass_empty_rounded),
        onPressed: null,
      ),
      error: (error, _) => IconButton(
        tooltip: 'Database locked — tap to unlock',
        icon: Icon(
          Icons.lock_rounded,
          color: Theme.of(context).colorScheme.error,
        ),
        onPressed: () => retryDatabaseUnlock(ref),
      ),
      data: (_) => IconButton(
        tooltip: 'Database unlocked',
        icon: const Icon(Icons.lock_open_rounded, color: Colors.green),
        onPressed: () {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(content: Text('Database is unlocked.')),
            );
        },
      ),
    );
  }
}

/// Invalidates the database provider chain so the next read re-runs the
/// biometric gate — the same recovery action `UnlockErrorBanner` and
/// [DatabaseStatusIndicator] both offer.
void retryDatabaseUnlock(WidgetRef ref) {
  ref
    ..invalidate(appDatabaseProvider)
    ..invalidate(cycleDayLogRepositoryProvider)
    ..invalidate(todayLogProvider);
}
