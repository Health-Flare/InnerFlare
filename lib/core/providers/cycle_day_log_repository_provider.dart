import 'package:inner_flare/core/providers/database_provider.dart';
import 'package:inner_flare/data/repositories/cycle_day_log_repository.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cycle_day_log_repository_provider.g.dart';

@Riverpod(keepAlive: true)
Future<CycleDayLogRepository> cycleDayLogRepository(Ref ref) async {
  final db = await ref.watch(appDatabaseProvider.future);
  return CycleDayLogRepository(db);
}
