import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inner_flare/core/providers/database_provider.dart';
import 'package:inner_flare/core/theme/app_theme.dart';
import 'package:inner_flare/features/dashboard/widgets/database_status_indicator.dart';

/// The dedicated, full-screen unlock prompt shown while the encrypted
/// database is opening or has failed to open — first open of a session and
/// any later re-open alike (docs/features/unlock.feature). Deliberately
/// uses the same layout, colors, and wording as [AppLockScreen] so the two
/// moments read as one unlock experience rather than two.
///
/// The biometric/passcode prompt itself is already triggered automatically
/// here, with no tap needed: `appDatabaseProvider` starts `AppDatabase`'s
/// `open()` — which authenticates before it does anything else — the
/// moment it's first watched, which is what showing this screen does.
/// Retrying after a failure is the only thing that needs a tap, via
/// [retryDatabaseUnlock].
class AppUnlockScreen extends ConsumerWidget {
  const AppUnlockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbAsync = ref.watch(appDatabaseProvider);
    final failed = dbAsync.hasError;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF17272C), Color(0xFF0B1416)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_rounded,
                    color: AppColors.softOrange,
                    size: 56,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Inner Flare is locked',
                    style: TextStyle(
                      color: AppColors.cream,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    failed
                        ? "That didn't go through, so your data stays "
                              'hidden until you try again.'
                        : 'Authenticate to view your data.',
                    style: const TextStyle(
                      color: Color(0xFFB7C4C7),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (failed) ...[
                    const SizedBox(height: 32),
                    FilledButton(
                      onPressed: () => retryDatabaseUnlock(ref),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.emberOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Unlock'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
