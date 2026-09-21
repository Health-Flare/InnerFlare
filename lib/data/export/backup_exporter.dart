import 'package:inner_flare/data/database/schema.dart';
import 'package:inner_flare/data/export/backup_data.dart';
import 'package:inner_flare/data/export/backup_file_codec.dart';
import 'package:inner_flare/data/repositories/cycle_day_log_repository.dart';
import 'package:inner_flare/data/repositories/tracked_symptoms_repository.dart';

/// Gathers the portable data (see [BackupData]) and encodes it as an
/// export file's contents (docs/features/export.feature). Pure data
/// gathering + encoding: writing the result to disk and presenting the OS
/// share sheet is the caller's job (lib/features/export/screens/
/// export_screen.dart), so this class has no I/O of its own and "export
/// never happens automatically" is enforced by nothing calling it outside
/// a user tapping Export.
class BackupExporter {
  BackupExporter({
    required CycleDayLogRepository cycleDayLogRepository,
    required TrackedSymptomsRepository trackedSymptomsRepository,
    BackupFileCodec? codec,
    DateTime Function()? now,
  }) : _cycleDayLogRepository = cycleDayLogRepository,
       _trackedSymptomsRepository = trackedSymptomsRepository,
       _codec = codec ?? BackupFileCodec(),
       _now = now ?? DateTime.now;

  final CycleDayLogRepository _cycleDayLogRepository;
  final TrackedSymptomsRepository _trackedSymptomsRepository;
  final BackupFileCodec _codec;
  final DateTime Function() _now;

  /// Builds the file contents for an export. Plaintext unless [passphrase]
  /// is given, matching "Plaintext export is the default with encryption
  /// opt-in": the plaintext JSON only ever exists in memory, never
  /// written to disk, when a passphrase is supplied.
  Future<String> buildFileContents({String? passphrase}) async {
    final logs = await _cycleDayLogRepository.getAll();
    final symptoms = await _trackedSymptomsRepository.getAll();

    final data = BackupData(
      schemaVersion: schemaVersion,
      exportedAt: _now(),
      cycleDayLogs: logs,
      symptoms: symptoms,
    );

    return _codec.encode(data, passphrase: passphrase);
  }
}
