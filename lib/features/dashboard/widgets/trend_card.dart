import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inner_flare/core/providers/dashboard_visualization_displays_provider.dart';
import 'package:inner_flare/core/theme/app_theme.dart';
import 'package:inner_flare/models/dashboard_card.dart';

/// A trend card on the dashboard (docs/features/dashboard_visualizations
/// .feature) — a bar or line chart of a data series over time, with the
/// series average marked as a reference. No charting package: this is a
/// [CustomPainter], matching CLAUDE.md's "Lightweight by Default".
class TrendCard extends ConsumerWidget {
  const TrendCard({super.key, required this.instance, this.onTap});

  final DashboardCardInstance instance;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayAsync = ref.watch(trendCardDisplayProvider(instance));

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
        data: (display) => _TrendContent(display: display),
      ),
    );
  }
}

class _TrendContent extends StatelessWidget {
  const _TrendContent({required this.display});

  final TrendCardDisplay display;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          display.metric.label,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        if (!display.metric.isImplemented)
          Text(
            'Coming soon — this data point isn\'t tracked yet.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.deepTeal.withValues(alpha: 0.7),
            ),
          )
        else if (!display.hasEnoughHistory)
          Text(
            'Not enough cycles logged yet — at least 2 complete cycles are '
            'needed before a trend can be shown.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.deepTeal.withValues(alpha: 0.7),
            ),
          )
        else
          SizedBox(
            height: 120,
            child: CustomPaint(
              size: Size.infinite,
              painter: _TrendPainter(
                values: display.cycleLengths,
                average: display.averageCycleLength,
                chartType: display.chartType,
                barColor: AppColors.emberOrange,
                latestBarColor: AppColors.deepTeal,
                averageLineColor: AppColors.midTeal,
              ),
            ),
          ),
      ],
    );
  }
}

class _TrendPainter extends CustomPainter {
  const _TrendPainter({
    required this.values,
    required this.average,
    required this.chartType,
    required this.barColor,
    required this.latestBarColor,
    required this.averageLineColor,
  });

  final List<int> values;
  final double? average;
  final TrendChartType chartType;
  final Color barColor;
  final Color latestBarColor;
  final Color averageLineColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxValue = values.reduce((a, b) => a > b ? a : b).toDouble();
    // Pad the scale so the average line and tallest bar are never flush
    // against the chart's edges.
    final scaleMax = maxValue <= 0 ? 1.0 : maxValue * 1.15;
    final scaleMin = 0.0;

    double yFor(num value) {
      final t = (value - scaleMin) / (scaleMax - scaleMin);
      return size.height - (t.clamp(0.0, 1.0) * size.height);
    }

    if (chartType == TrendChartType.bar) {
      final barWidth = size.width / (values.length * 1.6);
      final gap = (size.width - barWidth * values.length) / (values.length + 1);
      for (var i = 0; i < values.length; i++) {
        final isLatest = i == values.length - 1;
        final left = gap + i * (barWidth + gap);
        final top = yFor(values[i]);
        final paint = Paint()..color = isLatest ? latestBarColor : barColor;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(left, top, left + barWidth, size.height),
            const Radius.circular(4),
          ),
          paint,
        );
      }
    } else {
      final path = Path();
      final stepX = values.length > 1 ? size.width / (values.length - 1) : 0.0;
      for (var i = 0; i < values.length; i++) {
        final point = Offset(i * stepX, yFor(values[i]));
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      final linePaint = Paint()
        ..color = barColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(path, linePaint);

      final latestPoint = Offset(
        (values.length - 1) * stepX,
        yFor(values.last),
      );
      canvas.drawCircle(latestPoint, 5, Paint()..color = latestBarColor);
    }

    if (average != null) {
      final y = yFor(average!);
      final dashPaint = Paint()
        ..color = averageLineColor.withValues(alpha: 0.6)
        ..strokeWidth = 1.5;
      const dashWidth = 5.0;
      const dashGap = 4.0;
      var startX = 0.0;
      while (startX < size.width) {
        canvas.drawLine(
          Offset(startX, y),
          Offset((startX + dashWidth).clamp(0, size.width), y),
          dashPaint,
        );
        startX += dashWidth + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.average != average ||
        oldDelegate.chartType != chartType;
  }
}
