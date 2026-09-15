import 'package:inner_flare/core/providers/cycle_day_log_repository_provider.dart';
import 'package:inner_flare/core/providers/tracked_symptoms_repository_provider.dart';
import 'package:inner_flare/data/export/backup_importer.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'backup_importer_provider.g.dart';

@Riverpod(keepAlive: true)
Future<BackupImporter> backupImporter(Ref ref) async {
  final cycleDayLogRepository = await ref.watch(
    cycleDayLogRepositoryProvider.future,
  );
  final trackedSymptomsRepository = await ref.watch(
    trackedSymptomsRepositoryProvider.future,
  );
  return BackupImporter(
    cycleDayLogRepository: cycleDayLogRepository,
    trackedSymptomsRepository: trackedSymptomsRepository,
  );
}
