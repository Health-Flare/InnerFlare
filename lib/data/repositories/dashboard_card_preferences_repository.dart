import 'package:inner_flare/data/database/schema.dart';
import 'package:inner_flare/models/dashboard_card.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Hand-written SQL access to `dashboard_card_preferences`. Maps rows
/// to/from [DashboardCardPreference]; providers call this, never raw SQL
/// directly.
class DashboardCardPreferencesRepository {
  DashboardCardPreferencesRepository(this._db);

  final Database _db;

  /// The full set of cards in display order, merging saved rows with any
  /// [DashboardCard] not yet in the database (e.g. a card added in a later
  /// app version) appended at the end, visible by default — matching
  /// "every default card can be hidden, and no card is marked as
  /// mandatory or unremovable" without ever losing a saved order.
  Future<List<DashboardCardPreference>> getAll() async {
    final rows = await _db.query(
      dashboardCardPreferencesTable,
      orderBy: 'sort_order ASC',
    );
    final saved = <DashboardCard, DashboardCardPreference>{
      for (final row in rows)
        DashboardCard.values.byName(
          row['card_id'] as String,
        ): DashboardCardPreference(
          card: DashboardCard.values.byName(row['card_id'] as String),
          visible: (row['visible'] as int) == 1,
          order: row['sort_order'] as int,
        ),
    };

    final result = saved.values.toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    var nextOrder = result.isEmpty ? 0 : result.last.order + 1;
    for (final card in DashboardCard.values) {
      if (!saved.containsKey(card)) {
        result.add(
          DashboardCardPreference(card: card, visible: true, order: nextOrder),
        );
        nextOrder++;
      }
    }
    return result;
  }

  /// Replaces the entire saved layout with [prefs], in list order.
  Future<void> saveAll(List<DashboardCardPreference> prefs) async {
    await _db.transaction((txn) async {
      await txn.delete(dashboardCardPreferencesTable);
      for (var i = 0; i < prefs.length; i++) {
        final pref = prefs[i];
        await txn.insert(dashboardCardPreferencesTable, {
          'card_id': pref.card.name,
          'visible': pref.visible ? 1 : 0,
          'sort_order': i,
        });
      }
    });
  }
}
