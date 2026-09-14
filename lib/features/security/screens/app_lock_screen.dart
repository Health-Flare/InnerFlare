import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inner_flare/core/providers/app_lock_provider.dart';
import 'package:inner_flare/core/providers/biometric_gate_provider.dart';
import 'package:inner_flare/core/providers/reauthenticating_provider.dart';
import 'package:inner_flare/core/theme/app_theme.dart';

/// Covers the app after it's been backgrounded past the idle timeout
/// (docs/features/app_lock.feature). Never authenticates on its own when
/// shown — same "the user decides when to try" rule as
/// [UnlockErrorBanner] — so re-showing this screen never stacks a second
/// system biometric prompt on top of one already in flight.
class AppLockScreen extends ConsumerStatefulWidget {
  const AppLockScreen({super.key});

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen> {
  bool _authenticating = false;

  @override
  void initState() {
    super.initState();
    // Fire the prompt for the user as soon as this screen appears — see
    // docs/features/unlock.feature. Scheduled for after the first frame
    // (rather than called straight from initState) since it calls
    // setState; not repeated on rebuilds because initState only runs
    // once per mount, and a still-locked rebuild reuses this same State
    // (see AppLockGate's `if (isLocked) const AppLockScreen()`).
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  Future<void> _unlock() async {
    setState(() => _authenticating = true);
    // Flagged for the whole native-prompt round trip so AppLockGate can
    // ignore the inactive/resumed transitions that prompt itself causes —
    // see reauthenticating_provider.dart for why that matters.
    final reauthFlag = ref.read(reauthenticationFlagProvider);
    reauthFlag.inProgress = true;
    final authenticated = await ref.read(biometricGateProvider).authenticate();
    reauthFlag.inProgress = false;
    if (!mounted) return;
    setState(() => _authenticating = false);
    if (authenticated) {
      ref.read(appLockProvider.notifier).unlock();
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  const Text(
                    "You've been away a while, so your data is hidden "
                    'until you unlock again.',
                    style: TextStyle(color: Color(0xFFB7C4C7), fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: _authenticating ? null : _unlock,
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
                    child: Text(_authenticating ? 'Unlocking…' : 'Unlock'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
