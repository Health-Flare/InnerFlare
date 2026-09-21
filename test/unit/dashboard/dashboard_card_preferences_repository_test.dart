// Exercises docs/features/dashboard.feature and
// docs/features/dashboard_visualizations.feature against the repository
// directly (no widgets). See
// lib/data/repositories/dashboard_card_preferences_repository.dart.

import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/data/database/schema.dart';
import 'package:inner_flare/data/repositories/dashboard_card_preferences_repository.dart';
import 'package:inner_flare/models/dashboard_card.dart';
import 'package:inner_flare/models/quick_stat.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../helpers/test_database.dart';

void main() {
  setUpAll(useInMemoryTestDatabaseFactory);

  late Database db;
  late DashboardCardPreferencesRepository repository;

  setUp(() async {
    db = await openInMemoryTestDatabase(
      onCreate: onCreate,
      version: schemaVersion,
    );
    repository = DashboardCardPreferencesRepository(db);
  });

  tearDown(() => db.close());

  test('a fresh install auto-populates two quick stats, calendar, and '
      'insights, visible, in enum order, but no gauge/trend card', () async {
    final all = await repository.getAll();
    expect(all.map((c) => c.kind), [
      DashboardCardKind.quickStat,
      DashboardCardKind.quickStat,
      DashboardCardKind.calendar,
      DashboardCardKind.insights,
    ]);
    expect(all.every((c) => c.visible), isTrue);
  });

  test(
    'adding a gauge card via saveAll persists its kind, id, and config',
    () async {
      final initial = await repository.getAll();
      final gauge = newGaugeCardInstance(
        order: initial.length,
        mode: GaugeCardMode.estimatedDaysUntilNextPeriod,
      );
      await repository.saveAll([...initial, gauge]);

      final all = await repository.getAll();
      final saved = all.firstWhere((c) => c.id == gauge.id);
      expect(saved.kind, DashboardCardKind.gauge);
      expect(saved.gaugeMode, GaugeCardMode.estimatedDaysUntilNextPeriod);
    },
  );

  test('two trend cards for different metrics coexist as separate '
      'instances, per "Additional data points can be added as their own '
      'cards"', () async {
    final initial = await repository.getAll();
    final first = newTrendCardInstance(
      order: initial.length,
      metric: TrendCardMetric.previousCycleLengths,
      chartType: TrendChartType.bar,
    );
    final second = newTrendCardInstance(
      order: initial.length + 1,
      metric: TrendCardMetric.cycleLengthVariability,
      chartType: TrendChartType.line,
    );
    await repository.saveAll([...initial, first, second]);

    final all = await repository.getAll();
    final trendCards = all.where((c) => c.kind == DashboardCardKind.trend);
    expect(trendCards.length, 2);
    expect(trendCards.map((c) => c.trendMetric).toSet(), {
      TrendCardMetric.previousCycleLengths,
      TrendCardMetric.cycleLengthVariability,
    });
  });

  test('removing a card (saveAll without it) doesn\'t bring it back on '
      'the next getAll: unlike calendar/insights, gauge/trend cards are '
      'never auto-appended', () async {
    final initial = await repository.getAll();
    final gauge = newGaugeCardInstance(order: initial.length);
    await repository.saveAll([...initial, gauge]);
    expect((await repository.getAll()).length, initial.length + 1);

    final withoutGauge = (await repository.getAll())
        .where((c) => c.id != gauge.id)
        .toList();
    await repository.saveAll(withoutGauge);

    final all = await repository.getAll();
    expect(all.any((c) => c.id == gauge.id), isFalse);
    expect(all.length, initial.length);
  });

  test('switching a gauge card\'s mode persists across getAll calls, per '
      '"the choice is saved per-device, the same way other dashboard '
      'preferences are saved"', () async {
    final initial = await repository.getAll();
    final gauge = newGaugeCardInstance(
      order: initial.length,
      mode: GaugeCardMode.daysSinceLastPeriod,
    );
    await repository.saveAll([...initial, gauge]);

    final saved = (await repository.getAll()).firstWhere(
      (c) => c.id == gauge.id,
    );
    final switched = saved.withConfigValue(
      DashboardCardConfigKeys.gaugeMode,
      GaugeCardMode.estimatedDaysUntilNextPeriod.name,
    );
    await repository.saveAll([
      for (final c in await repository.getAll())
        if (c.id == switched.id) switched else c,
    ]);

    final reloaded = (await repository.getAll()).firstWhere(
      (c) => c.id == gauge.id,
    );
    expect(reloaded.gaugeMode, GaugeCardMode.estimatedDaysUntilNextPeriod);
  });

  test('a device upgrading from schema_version 5 keeps its saved card and '
      'its quick stat customization through the migration, with card_kind '
      'backfilled from the old card_id and quick stats folded in', () async {
    // sqflite caches open databases by path, and every in-memory database
    // shares the literal ":memory:" path (see CLAUDE.md "sqflite on
    // desktop test runners"). Close the outer setUp's db first so this
    // test's own openInMemoryTestDatabase call below doesn't silently
    // reuse it (which already has the post-migration schema applied).
    await db.close();

    // Recreate exactly the pre-v6 dashboard_card_preferences shape and the
    // quick_stat_preferences table every schema_version 5 device already
    // has, seeded the way each table's schema_version 5 repository would
    // have, then run the real onUpgrade path.
    final oldShapeDb = await openInMemoryTestDatabase(
      onCreate: (oldDb, _) async {
        await oldDb.execute('''
          CREATE TABLE dashboard_card_preferences (
            card_id TEXT PRIMARY KEY,
            visible INTEGER NOT NULL DEFAULT 1,
            sort_order INTEGER NOT NULL
          )
        ''');
        await oldDb.insert('dashboard_card_preferences', {
          'card_id': 'insights',
          'visible': 0,
          'sort_order': 0,
        });
        await oldDb.execute('''
          CREATE TABLE quick_stat_preferences (
            slot INTEGER PRIMARY KEY,
            stat_type TEXT NOT NULL,
            reference_point TEXT NOT NULL
          )
        ''');
        // Only slot 0 was ever customized; slot 1 stays at its default.
        await oldDb.insert('quick_stat_preferences', {
          'slot': 0,
          'stat_type': 'daysSinceLastPeriod',
          'reference_point': 'periodStart',
        });
      },
      version: 5,
    );

    // sqflite only calls onUpgrade on a version bump through openDatabase's
    // own version-tracking, which the FFI in-memory helper doesn't expose
    // directly, so call the real migration function against this exact
    // pre-v6 connection instead, the same call `openDatabase` would make.
    await onUpgrade(oldShapeDb, 5, schemaVersion);

    final migrated = await DashboardCardPreferencesRepository(
      oldShapeDb,
    ).getAll();
    final insights = migrated.firstWhere((c) => c.id == 'insights');
    expect(insights.kind, DashboardCardKind.insights);
    expect(insights.visible, isFalse);

    final quickStat0 = migrated.firstWhere((c) => c.id == 'quick-stat-0');
    expect(quickStat0.quickStatType, QuickStatType.daysSinceLastPeriod);
    expect(
      quickStat0.quickStatReferencePoint,
      QuickStatReferencePoint.periodStart,
    );
    final quickStat1 = migrated.firstWhere((c) => c.id == 'quick-stat-1');
    expect(quickStat1.quickStatType, QuickStatType.estimatedDaysToNextPeriod);

    await oldShapeDb.close();
  });
}
