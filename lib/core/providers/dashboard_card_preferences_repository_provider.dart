import 'package:inner_flare/core/providers/database_provider.dart';
import 'package:inner_flare/data/repositories/dashboard_card_preferences_repository.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dashboard_card_preferences_repository_provider.g.dart';

@Riverpod(keepAlive: true)
Future<DashboardCardPreferencesRepository> dashboardCardPreferencesRepository(
  Ref ref,
) async {
  final db = await ref.watch(appDatabaseProvider.future);
  return DashboardCardPreferencesRepository(db);
}
