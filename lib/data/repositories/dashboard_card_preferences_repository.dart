import 'dart:convert';

import 'package:inner_flare/data/database/schema.dart';
import 'package:inner_flare/models/dashboard_card.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Hand-written SQL access to `dashboard_card_preferences`. Maps rows
/// to/from [DashboardCardInstance]; providers call this, never raw SQL
/// directly. Stays type-agnostic about card kinds — `config` is persisted
/// as an opaque JSON string, never parsed here; only
/// [DashboardCardInstance]'s getters (`gaugeMode`, `trendMetric`, ...) know
/// what the keys mean.
class DashboardCardPreferencesRepository {
  DashboardCardPreferencesRepository(this._db);

  final Database _db;

  /// The full set of card instances in display order, merging saved rows
  /// with any *default* [DashboardCardKind] not yet in the database (e.g.
  /// a default card added in a later app version) appended at the end,
  /// visible by default — matching "every default card can be hidden, and
  /// no card is marked as mandatory or unremovable". Gauge/trend cards are
  /// never auto-appended this way: they only exist once the user adds one
  /// via the add-card flow (see [addCard]).
  Future<List<DashboardCardInstance>> getAll() async {
    final rows = await _db.query(
      dashboardCardPreferencesTable,
      orderBy: 'sort_order ASC',
    );
    final result = [for (final row in rows) _fromRow(row)];

    final present = result.map((c) => c.kind).toSet();
    var nextOrder = result.isEmpty ? 0 : result.last.order + 1;
    for (final kind in DashboardCardKind.values.where((k) => k.isDefault)) {
      if (!present.contains(kind)) {
        result.add(
          DashboardCardInstance(
            id: kind.name,
            kind: kind,
            visible: true,
            order: nextOrder,
          ),
        );
        nextOrder++;
      }
    }
    return result;
  }

  /// Replaces the entire saved layout with [instances], in list order.
  Future<void> saveAll(List<DashboardCardInstance> instances) async {
    await _db.transaction((txn) async {
      await txn.delete(dashboardCardPreferencesTable);
      for (var i = 0; i < instances.length; i++) {
        await txn.insert(
          dashboardCardPreferencesTable,
          _toRow(instances[i], i),
        );
      }
    });
  }

  DashboardCardInstance _fromRow(Map<String, Object?> row) {
    final rawConfig = row['config'] as String?;
    final config = (rawConfig == null || rawConfig.isEmpty)
        ? const <String, String>{}
        : Map<String, String>.from(jsonDecode(rawConfig) as Map);
    return DashboardCardInstance(
      id: row['card_id'] as String,
      kind: DashboardCardKind.values.byName(row['card_kind'] as String),
      visible: (row['visible'] as int) == 1,
      order: row['sort_order'] as int,
      config: config,
    );
  }

  Map<String, Object?> _toRow(DashboardCardInstance instance, int order) {
    return {
      'card_id': instance.id,
      'card_kind': instance.kind.name,
      'visible': instance.visible ? 1 : 0,
      'sort_order': order,
      'config': instance.config.isEmpty ? null : jsonEncode(instance.config),
    };
  }
}
