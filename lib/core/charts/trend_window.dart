/// How many cycles a trend chart shows, given the room it has
/// (docs/features/dashboard_visualizations.feature, "A trend chart shows
/// only as many recent cycles as its card has room for").
///
/// Pure: no Flutter, no database. The widget measures its plot area and
/// asks for a capacity; everything else is arithmetic.
library;

import 'dart:math' as math;

import 'package:inner_flare/models/dashboard_card.dart';

/// Per-chart-type limits on the x axis.
///
/// [minSlotWidth] is the narrowest horizontal space one data point gets
/// before the chart stops reading clearly. [maxPoints] is a hard ceiling
/// that applies however wide the card is.
class TrendWindowPolicy {
  const TrendWindowPolicy({
    required this.minSlotWidth,
    required this.maxPoints,
  });

  /// Bars: 18pt per slot keeps each bar around 11pt wide with a visible
  /// gap (the painter draws bars at slot / 1.6). Capped at 12, roughly a
  /// year of cycles: past that, bars turn into a barcode and comparing
  /// one against its neighbours stops working.
  static const bar = TrendWindowPolicy(minSlotWidth: 18, maxPoints: 12);

  /// Lines: a point every 12pt still reads as a line with distinguishable
  /// turns. Capped at 24, roughly two years, so a long history still
  /// shows its recent shape rather than a flat smear.
  static const line = TrendWindowPolicy(minSlotWidth: 12, maxPoints: 24);

  /// Fewer than 2 points is not a trend; the card already says so before
  /// it ever draws a chart.
  static const minPoints = 2;

  final double minSlotWidth;
  final int maxPoints;

  static TrendWindowPolicy forChartType(TrendChartType type) => switch (type) {
    TrendChartType.bar => bar,
    TrendChartType.line => line,
  };

  /// How many points fit in a plot area [plotWidth] logical pixels wide.
  int capacityFor(double plotWidth) {
    if (!plotWidth.isFinite || plotWidth <= 0) return minPoints;
    final fits = (plotWidth / minSlotWidth).floor();
    return math.max(minPoints, math.min(fits, maxPoints));
  }
}

/// The slice of a series a chart actually draws.
class TrendWindow {
  const TrendWindow({required this.visible, required this.total});

  /// The most recent values, oldest first.
  final List<int> visible;

  /// How many values the full series has.
  final int total;

  bool get isTruncated => visible.length < total;
}

/// The last [capacity] values of [values], oldest first. Never mutates
/// [values].
TrendWindow recentWindow(List<int> values, int capacity) {
  final visible = values.length <= capacity
      ? List<int>.unmodifiable(values)
      : List<int>.unmodifiable(values.sublist(values.length - capacity));
  return TrendWindow(visible: visible, total: values.length);
}
