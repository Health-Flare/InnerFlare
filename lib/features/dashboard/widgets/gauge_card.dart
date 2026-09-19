import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inner_flare/core/providers/dashboard_visualization_displays_provider.dart';
import 'package:inner_flare/core/theme/app_theme.dart';
import 'package:inner_flare/models/dashboard_card.dart';

/// A gauge card on the dashboard (docs/features/dashboard_visualizations
/// .feature) — shows either "days since last period" or "estimated days
/// until next period", filled relative to the user's own average cycle
/// length rather than a fixed scale. No charting package: this is a
/// [CustomPainter] arc, matching CLAUDE.md's "Lightweight by Default" —
/// this is a simple enough shape not to justify a new dependency.
class GaugeCard extends ConsumerWidget {
  const GaugeCard({super.key, required this.instance, this.onTap});

  final DashboardCardInstance instance;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayAsync = ref.watch(gaugeCardDisplayProvider(instance));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.emberOrange.withValues(alpha: 0.15),
        ),
      ),
      child: displayAsync.when(
        loading: () => const SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => Text('Couldn\'t load: $error'),
        data: (display) => _GaugeContent(display: display),
      ),
    );
  }
}

class _GaugeContent extends StatelessWidget {
  const _GaugeContent({required this.display});

  final GaugeCardDisplay display;

  @override
  Widget build(BuildContext context) {
    final value = display.value;
    final hasValue = value != null;
    final label = display.mode.label;
    final isEstimate =
        display.mode == GaugeCardMode.estimatedDaysUntilNextPeriod;

    final String valueText;
    if (!hasValue) {
      valueText = '—';
    } else if (isEstimate && value < 0) {
      valueText = '${-value}d over';
    } else if (display.isThinHistory) {
      valueText = '~$value';
    } else {
      valueText = '$value';
    }

    return Row(
      children: [
        SizedBox(
          width: 76,
          height: 76,
          child: CustomPaint(
            painter: _GaugePainter(
              fillFraction: display.fillFraction ?? 0,
              trackColor: AppColors.softOrange.withValues(alpha: 0.25),
              fillColor: AppColors.emberOrange,
            ),
            child: Center(
              child: Text(
                hasValue ? valueText : 'No data',
                textAlign: TextAlign.center,
                style: hasValue
                    ? Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      )
                    : Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                !hasValue
                    ? 'Log a period start to see this.'
                    : display.isThinHistory
                    ? isEstimate
                          ? 'A rough range — not enough cycle history yet '
                                'for a precise estimate.'
                          : 'days, counted from the period start'
                    : isEstimate
                    ? 'days, an estimate'
                    : 'days, counted from the period start',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.deepTeal.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Draws a ring gauge: a full-circle track plus an arc filled clockwise
/// from the top for [fillFraction] of the circle (0 to 1).
class _GaugePainter extends CustomPainter {
  const _GaugePainter({
    required this.fillFraction,
    required this.trackColor,
    required this.fillColor,
  });

  final double fillFraction;
  final Color trackColor;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.shortestSide * 0.14;
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.shortestSide - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    if (fillFraction <= 0) return;
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * fillFraction.clamp(0.0, 1.0),
      false,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.fillFraction != fillFraction ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.fillColor != fillColor;
  }
}
