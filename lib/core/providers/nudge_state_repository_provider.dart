import 'package:inner_flare/core/providers/database_provider.dart';
import 'package:inner_flare/data/repositories/nudge_state_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'nudge_state_repository_provider.g.dart';

@Riverpod(keepAlive: true)
Future<NudgeStateRepository> nudgeStateRepository(Ref ref) async {
  final db = await ref.watch(appDatabaseProvider.future);
  return NudgeStateRepository(db);
}
