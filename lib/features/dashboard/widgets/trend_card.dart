import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inner_flare/core/providers/dashboard_visualization_displays_provider.dart';
import 'package:inner_flare/core/theme/app_theme.dart';
import 'package:inner_flare/models/dashboard_card.dart';

/// A trend card on the dashboard (docs/features/dashboard_visualizations
/// .feature), a bar or line chart of a data series over time, with the
/// series average marked as a reference. No charting package: this is a
/// [CustomPainter], matching CLAUDE.md's "Lightweight by Default".
class TrendCard extends ConsumerWidget {
  const TrendCard({super.key, required this.instance, this.onTap});

  final DashboardCardInstance instance;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayAsync = ref.watch(trendCardDisplayProvider(instance));

    final card = Container(
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

    // Tappable only once there's a real series to summarize, see
    // "A trend card becomes tappable once it has real history to
    // summarize" / "...without enough history isn't tappable".
    final isTappable = displayAsync.value?.hasEnoughHistory ?? false;
    if (!isTappable || onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: card,
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
            'Coming soon: this data point isn\'t tracked yet.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.deepTeal.withValues(alpha: 0.7),
            ),
          )
        else if (!display.hasEnoughHistory)
          Text(
            'Not enough cycles logged yet: at least 2 complete cycles are '
            'needed before a trend can be shown.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.deepTeal.withValues(alpha: 0.7),
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 120,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TrendYAxisLabels(
                      maxValue: _TrendPainter.scaleMaxFor(display.cycleLengths),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
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
                ),
              ),
              const SizedBox(height: 8),
              _TrendLegend(
                seriesColor: AppColors.emberOrange,
                latestColor: AppColors.deepTeal,
                averageColor: AppColors.midTeal,
                showAverage: display.averageCycleLength != null,
              ),
            ],
          ),
      ],
    );
  }
}

/// Numeric y-axis scale for [_TrendPainter], "0" at the bottom and the
/// chart's padded max at the top, matching [_TrendPainter.yFor] so the
/// labels line up with where the painter actually places 0 and
/// [maxValue] on the canvas.
class _TrendYAxisLabels extends StatelessWidget {
  const _TrendYAxisLabels({required this.maxValue});

  final double maxValue;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: AppColors.deepTeal.withValues(alpha: 0.6),
      fontSize: 10,
    );
    return SizedBox(
      width: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('${maxValue.round()}d', style: style),
          Text('0d', style: style),
        ],
      ),
    );
  }
}

/// Explains what each color in [_TrendPainter] means: the series/latest
/// distinction and (when there's enough history) the dashed average
/// line, per docs/features/dashboard_visualizations.feature's "the most
/// recent cycle is visually distinguishable as the latest" and "a
/// reference line or annotation marks the ... average".
class _TrendLegend extends StatelessWidget {
  const _TrendLegend({
    required this.seriesColor,
    required this.latestColor,
    required this.averageColor,
    required this.showAverage,
  });

  final Color seriesColor;
  final Color latestColor;
  final Color averageColor;
  final bool showAverage;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        _TrendLegendItem(color: seriesColor, label: 'Cycle length'),
        _TrendLegendItem(color: latestColor, label: 'Latest'),
        if (showAverage)
          _TrendLegendItem(color: averageColor, label: 'Average', dashed: true),
      ],
    );
  }
}

class _TrendLegendItem extends StatelessWidget {
  const _TrendLegendItem({
    required this.color,
    required this.label,
    this.dashed = false,
  });

  final Color color;
  final String label;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (dashed)
          SizedBox(
            width: 14,
            height: 10,
            child: CustomPaint(painter: _DashedSwatchPainter(color: color)),
          )
        else
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.deepTeal.withValues(alpha: 0.7),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

/// A small dashed-line swatch, matching the average line's dash style in
/// [_TrendPainter].
class _DashedSwatchPainter extends CustomPainter {
  const _DashedSwatchPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    final y = size.height / 2;
    const dashWidth = 4.0;
    const dashGap = 3.0;
    var startX = 0.0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, y),
        Offset((startX + dashWidth).clamp(0, size.width), y),
        paint,
      );
      startX += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedSwatchPainter oldDelegate) =>
      oldDelegate.color != color;
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

  /// The padded top of the y-axis scale for [values], shared with
  /// [_TrendYAxisLabels] so its top label lines up with where this
  /// painter actually places that value on the canvas (see [paint]'s
  /// `yFor`). Padded so the average line and tallest bar/point are never
  /// flush against the chart's edges.
  static double scaleMaxFor(List<int> values) {
    if (values.isEmpty) return 1.0;
    final maxValue = values.reduce((a, b) => a > b ? a : b).toDouble();
    return maxValue <= 0 ? 1.0 : maxValue * 1.15;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final scaleMax = scaleMaxFor(values);
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
