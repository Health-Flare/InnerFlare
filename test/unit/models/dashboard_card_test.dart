// Exercises docs/features/dashboard_grid_layout.feature's resize scenarios
// against the model directly (no widgets, no database). See
// lib/models/dashboard_card.dart.

import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/models/dashboard_card.dart';

void main() {
  DashboardCardInstance instance({
    DashboardCardKind kind = DashboardCardKind.gauge,
    Map<String, String> config = const {},
  }) {
    return DashboardCardInstance(
      id: 'x',
      kind: kind,
      visible: true,
      order: 0,
      config: config,
    );
  }

  group('columnSpan/rowSpan', () {
    test('falls back to the kind\'s default when no override is stored', () {
      final gauge = instance(kind: DashboardCardKind.gauge);
      expect(gauge.columnSpan, 2);
      expect(gauge.rowSpan, 1);

      final calendar = instance(kind: DashboardCardKind.calendar);
      expect(calendar.columnSpan, 1);
      expect(calendar.rowSpan, 1);
    });

    test('reads a stored override over the kind default', () {
      final resized = instance(
        config: {
          DashboardCardConfigKeys.gridColumnSpan: '1',
          DashboardCardConfigKeys.gridRowSpan: '3',
        },
      );
      expect(resized.columnSpan, 1);
      expect(resized.rowSpan, 3);
    });

    test('clamps a stored value outside today\'s bounds, e.g. from an '
        'older or hand-edited backup', () {
      final tooBig = instance(
        config: {
          DashboardCardConfigKeys.gridColumnSpan: '9',
          DashboardCardConfigKeys.gridRowSpan: '99',
        },
      );
      expect(tooBig.columnSpan, dashboardGridMaxColumnSpan);
      expect(tooBig.rowSpan, dashboardGridMaxRowSpan);

      final tooSmall = instance(
        config: {
          DashboardCardConfigKeys.gridColumnSpan: '0',
          DashboardCardConfigKeys.gridRowSpan: '-1',
        },
      );
      expect(tooSmall.columnSpan, dashboardGridMinColumnSpan);
      expect(tooSmall.rowSpan, dashboardGridMinRowSpan);
    });

    test('falls back to the kind default for a non-numeric stored value', () {
      final malformed = instance(
        kind: DashboardCardKind.trend,
        config: {DashboardCardConfigKeys.gridColumnSpan: 'not-a-number'},
      );
      expect(malformed.columnSpan, DashboardCardKind.trend.defaultGridSpan.$1);
    });
  });

  group('withGridSpan', () {
    test('sets both dimensions and preserves other config', () {
      final original = instance(
        kind: DashboardCardKind.gauge,
        config: {DashboardCardConfigKeys.gaugeMode: 'daysSinceLastPeriod'},
      );

      final resized = original.withGridSpan(columnSpan: 1, rowSpan: 2);

      expect(resized.columnSpan, 1);
      expect(resized.rowSpan, 2);
      expect(resized.gaugeMode.name, 'daysSinceLastPeriod');
    });

    test('leaving a dimension null keeps that dimension unchanged', () {
      final original = instance().withGridSpan(columnSpan: 1, rowSpan: 2);

      final columnOnly = original.withGridSpan(columnSpan: 2);
      expect(columnOnly.columnSpan, 2);
      expect(columnOnly.rowSpan, 2);

      final rowOnly = original.withGridSpan(rowSpan: 3);
      expect(rowOnly.columnSpan, 1);
      expect(rowOnly.rowSpan, 3);
    });

    test('clamps out-of-bounds values passed in directly', () {
      final resized = instance().withGridSpan(columnSpan: 9, rowSpan: -5);
      expect(resized.columnSpan, dashboardGridMaxColumnSpan);
      expect(resized.rowSpan, dashboardGridMinRowSpan);
    });
  });
}
