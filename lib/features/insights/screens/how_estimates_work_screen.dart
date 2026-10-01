import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inner_flare/core/citations/medical_sources.dart';
import 'package:inner_flare/core/citations/open_source_link.dart';
import 'package:inner_flare/core/theme/app_theme.dart';

/// How each estimate is calculated and the published sources behind its
/// assumptions (docs/features/citations.feature). Reachable from the
/// Insights app bar, the prediction cards, the Calendar legend, and
/// Settings → About, so it never depends on having logged anything.
class HowEstimatesWorkScreen extends StatelessWidget {
  const HowEstimatesWorkScreen({super.key});

  /// Pushes this screen from anywhere that shows an estimate.
  static Future<void> open(BuildContext context) {
    return Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const HowEstimatesWorkScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: AppColors.deepTeal.withValues(alpha: 0.7),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('How estimates work')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            Text(
              'Inner Flare calculates every estimate from the dates you log. '
              'Where a calculation relies on a general assumption about '
              'menstrual cycles, the published source is listed below. '
              'These are estimates, not medical advice or a diagnosis.',
              style: muted,
            ),
            for (final explanation in estimateExplanations) ...[
              const SizedBox(height: 16),
              _ExplanationCard(explanation: explanation),
            ],
            const SizedBox(height: 16),
            Text(
              'Sources open in your browser when you tap them. Inner Flare '
              'does not connect to the internet itself.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExplanationCard extends StatelessWidget {
  const _ExplanationCard({required this.explanation});

  final EstimateExplanation explanation;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.emberOrange.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            explanation.title,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(explanation.method),
          const SizedBox(height: 8),
          Text(explanation.evidence),
          const SizedBox(height: 12),
          Text(
            explanation.sources.length == 1 ? 'Source' : 'Sources',
            style: textTheme.labelLarge?.copyWith(
              color: AppColors.deepTeal.withValues(alpha: 0.7),
            ),
          ),
          for (final source in explanation.sources) _SourceLink(source: source),
        ],
      ),
    );
  }
}

class _SourceLink extends ConsumerWidget {
  const _SourceLink({required this.source});

  final MedicalSource source;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: AppColors.deepTeal,
      decoration: TextDecoration.underline,
      height: 1.4,
    );

    return Semantics(
      link: true,
      child: InkWell(
        onTap: () => _open(context, ref),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(source.citation, style: style)),
              const SizedBox(width: 8),
              const Icon(Icons.open_in_new, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(sourceLinkOpenerProvider)(Uri.parse(source.url));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Could not open that link.')),
        );
    }
  }
}
