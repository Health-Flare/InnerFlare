import 'package:inner_flare/core/providers/database_provider.dart';
import 'package:inner_flare/data/repositories/quick_stat_preferences_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'quick_stat_preferences_repository_provider.g.dart';

@Riverpod(keepAlive: true)
Future<QuickStatPreferencesRepository> quickStatPreferencesRepository(
  Ref ref,
) async {
  final db = await ref.watch(appDatabaseProvider.future);
  return QuickStatPreferencesRepository(db);
}
