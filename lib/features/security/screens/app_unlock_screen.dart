import 'package:flutter/material.dart';
import 'package:inner_flare/core/theme/app_theme.dart';

/// The dedicated, full-screen unlock prompt shown whenever the encrypted
/// database isn't open: first open of a session and any later re-open
/// alike (docs/features/unlock.feature). Deliberately uses the same
/// layout, colors, and wording as `AppLockScreen` so the two moments read
/// as one unlock experience rather than two.
///
/// Never triggers the biometric/passcode prompt on its own: [onUnlock] is
/// only ever wired up to something when a tap should do that, so the
/// system prompt only ever appears in direct response to the user tapping
/// "Unlock", see [AppUnlockGate] for why (an automatically-fired prompt
/// can visually race a page transition and appear before the app has
/// shown any of its own branding).
class AppUnlockScreen extends StatelessWidget {
  const AppUnlockScreen({
    super.key,
    required this.busy,
    required this.failed,
    this.onUnlock,
  });

  /// Whether an attempt is currently in flight: disables the button and
  /// relabels it, same as `AppLockScreen`.
  final bool busy;

  /// Whether the most recent attempt failed: shows an explanation instead
  /// of the "why this screen exists" copy shown before any attempt.
  final bool failed;

  /// Called when the user taps "Unlock". Null (button disabled) exactly
  /// while [busy] is true.
  final VoidCallback? onUnlock;

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
                  Text(
                    failed
                        ? "That didn't go through, so your data stays "
                              'hidden until you try again.'
                        : 'Your cycle data is encrypted on this device. '
                              'Unlock with Face ID, Touch ID, or your '
                              'passcode to continue.',
                    style: const TextStyle(
                      color: Color(0xFFB7C4C7),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: onUnlock,
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
                    child: Text(busy ? 'Unlocking…' : 'Unlock'),
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
