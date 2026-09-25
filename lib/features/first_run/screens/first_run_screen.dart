import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inner_flare/core/providers/disclaimer_acknowledged_provider.dart';
import 'package:inner_flare/core/theme/app_theme.dart';
import 'package:inner_flare/features/first_run/widgets/disclaimer_body.dart';

/// Shows [FirstRunScreen] until the user acknowledges the disclaimer,
/// then shows [child].
///
/// Built only after [AppUnlockGate] has opened the encrypted database:
/// the flag lives in `security_settings`, so it cannot be read before
/// unlock. No cycle data is collected on this screen.
class FirstRunGate extends ConsumerWidget {
  const FirstRunGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final acknowledged = ref.watch(disclaimerAcknowledgedProvider);
    return acknowledged.when(
      // A static scaffold, never a spinner: an indeterminate animation
      // never lets WidgetTester.pumpAndSettle settle, and this gate sits
      // on the path every launch takes after unlock.
      loading: () => const Scaffold(),
      // Fail closed: a failed read must not skip the disclaimer.
      error: (_, _) => const FirstRunScreen(),
      data: (done) => done ? child : const FirstRunScreen(),
    );
  }
}

/// First-launch privacy and not-a-medical-device gate
/// (docs/features/first_run_disclaimer.feature). Continuing writes the
/// acknowledgement and does not ask for an account or a network grant.
class FirstRunScreen extends ConsumerWidget {
  const FirstRunScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome to Inner Flare',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      const Text('A few things to know before you start.'),
                      const SizedBox(height: 24),
                      const DisclaimerBody(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => _acknowledge(context, ref),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.emberOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _acknowledge(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(disclaimerAcknowledgedProvider.notifier).acknowledge();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              "Couldn't save that. Your data is unchanged. Try again.",
            ),
          ),
        );
    }
  }
}
