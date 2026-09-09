import 'package:inner_flare/core/providers/database_provider.dart';
import 'package:inner_flare/data/repositories/tracked_symptoms_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tracked_symptoms_repository_provider.g.dart';

@Riverpod(keepAlive: true)
Future<TrackedSymptomsRepository> trackedSymptomsRepository(Ref ref) async {
  final db = await ref.watch(appDatabaseProvider.future);
  return TrackedSymptomsRepository(db);
}
