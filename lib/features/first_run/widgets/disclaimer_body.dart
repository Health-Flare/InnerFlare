import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inner_flare/core/privacy/open_privacy_policy.dart';

/// The not-a-medical-device statement and the short privacy summary,
/// shared by the first-run gate and Settings → About.
///
/// Wording stays inside the published privacy policy: no extra claims.
class DisclaimerBody extends ConsumerWidget {
  const DisclaimerBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleStyle = Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Not a medical device', style: titleStyle),
        const SizedBox(height: 8),
        const Text(
          'Inner Flare is a tracking tool, not a medical or diagnostic '
          'device. Predictions are estimates based on the dates you log, '
          'not a diagnosis.',
        ),
        const SizedBox(height: 24),
        Text('Your data stays on this device', style: titleStyle),
        const SizedBox(height: 8),
        const Text(
          'Inner Flare does not collect, transmit, or share any of your '
          'data. Everything you log is encrypted and stored on your device '
          'only. There are no accounts, no servers, no analytics, and no '
          'third parties. The app requests no internet access.',
        ),
        const SizedBox(height: 12),
        const Text(
          'Nothing you log leaves this device unless you explicitly export '
          'a backup. Those files are never sent to the developer.',
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () => _openPrivacyPolicy(context, ref),
          icon: const Icon(Icons.open_in_new),
          label: const Text('Privacy policy'),
        ),
        const SizedBox(height: 8),
        Text(
          'Opens in your browser when you tap it. Inner Flare does not '
          'connect to the internet itself.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Future<void> _openPrivacyPolicy(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(privacyPolicyOpenerProvider)();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Could not open the privacy policy.')),
        );
    }
  }
}
