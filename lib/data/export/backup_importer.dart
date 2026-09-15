import 'package:inner_flare/data/database/schema.dart';
import 'package:inner_flare/data/export/backup_data.dart';
import 'package:inner_flare/data/export/backup_file_codec.dart';
import 'package:inner_flare/data/repositories/cycle_day_log_repository.dart';
import 'package:inner_flare/data/repositories/tracked_symptoms_repository.dart';
import 'package:inner_flare/models/cycle_day_log.dart';

/// The user's choice for how an import combines with what's already on
/// this device (docs/features/export.feature, "Import replaces or merges
/// into the local database").
enum ImportStrategy { replace, merge }

/// Validates and applies a backup file's contents to the local database
/// (docs/features/export.feature). Nothing is written until the file has
/// been fully parsed, decrypted (if needed), and version-checked — a
/// rejected file leaves the database untouched, matching "no partial data
/// is written."
class BackupImporter {
  BackupImporter({
    required CycleDayLogRepository cycleDayLogRepository,
    required TrackedSymptomsRepository trackedSymptomsRepository,
    BackupFileCodec? codec,
  }) : _cycleDayLogRepository = cycleDayLogRepository,
       _trackedSymptomsRepository = trackedSymptomsRepository,
       _codec = codec ?? BackupFileCodec();

  final CycleDayLogRepository _cycleDayLogRepository;
  final TrackedSymptomsRepository _trackedSymptomsRepository;
  final BackupFileCodec _codec;

  /// Whether [contents] is a passphrase-encrypted backup, so the import
  /// screen can prompt for a passphrase before calling [import]. Throws
  /// [InvalidBackupFile] if [contents] isn't a recognizable backup at all.
  bool isEncrypted(String contents) => _codec.isEncrypted(contents);

  /// Validates [contents] and, if valid, applies it using [strategy].
  ///
  /// Throws [InvalidBackupFile] for an unreadable or unrecognized file,
  /// [BackupPassphraseRequired] or [IncorrectBackupPassphrase] for a
  /// missing or wrong passphrase on an encrypted file, and
  /// [UnsupportedBackupSchemaVersion] if the file was exported from a
  /// newer app version than this one understands. None of these write
  /// anything to the database.
  Future<void> import(
    String contents, {
    required ImportStrategy strategy,
    String? passphrase,
  }) async {
    final data = await _codec.decode(contents, passphrase: passphrase);

    if (data.schemaVersion > schemaVersion) {
      throw UnsupportedBackupSchemaVersion(data.schemaVersion);
    }

    switch (strategy) {
      case ImportStrategy.replace:
        await _replace(data);
      case ImportStrategy.merge:
        await _merge(data);
    }
  }

  Future<void> _replace(BackupData data) async {
    await _cycleDayLogRepository.deleteAll();
    final sorted = [...data.cycleDayLogs]
      ..sort((a, b) => a.date.compareTo(b.date));
    for (final log in sorted) {
      await _cycleDayLogRepository.save(log);
    }
    await _trackedSymptomsRepository.replaceAll(data.symptoms);
  }

  Future<void> _merge(BackupData data) async {
    final existingByDate = {
      for (final log in await _cycleDayLogRepository.getAll())
        _dateKey(log.date): log,
    };
    final importedByDate = {
      for (final log in data.cycleDayLogs) _dateKey(log.date): log,
    };

    final allDates = {...existingByDate.keys, ...importedByDate.keys}.toList()
      ..sort();

    for (final dateKey in allDates) {
      final merged = _mergeLog(
        existing: existingByDate[dateKey],
        imported: importedByDate[dateKey],
      );
      await _cycleDayLogRepository.save(merged);
    }

    await _trackedSymptomsRepository.upsertIfAbsent(data.symptoms);
  }

  /// Combines the two logs for the same date, if both exist. Whatever is
  /// already entered on this device wins field-by-field — merge never
  /// overwrites data the user already has with something from the
  /// imported file — except:
  /// - symptom tags are unioned, since a set can hold both without either
  ///   being lost
  /// - a note present on both sides, and different, is concatenated so
  ///   neither is silently dropped
  CycleDayLog _mergeLog({CycleDayLog? existing, CycleDayLog? imported}) {
    if (existing == null) return imported!;
    if (imported == null) return existing;

    return CycleDayLog(
      date: existing.date,
      periodFlow: existing.periodFlow ?? imported.periodFlow,
      symptoms: {...existing.symptoms, ...imported.symptoms},
      note: _mergeNotes(existing.note, imported.note),
      ovulationTestResult:
          existing.ovulationTestResult ?? imported.ovulationTestResult,
      basalBodyTempCelsius:
          existing.basalBodyTempCelsius ?? imported.basalBodyTempCelsius,
    );
  }

  String? _mergeNotes(String? existing, String? imported) {
    if (existing == null || existing.isEmpty) return imported;
    if (imported == null || imported.isEmpty) return existing;
    if (existing == imported) return existing;
    return '$existing\n\n$imported';
  }

  static String _dateKey(DateTime date) {
    final dateOnly = DateTime.utc(date.year, date.month, date.day);
    return dateOnly.toIso8601String().split('T').first;
  }
}

/// Thrown when a backup's `schema_version` is newer than this app version
/// understands — importing it could silently drop fields this version
/// doesn't know about, so it's rejected rather than attempted.
class UnsupportedBackupSchemaVersion implements Exception {
  const UnsupportedBackupSchemaVersion(this.fileSchemaVersion);

  final int fileSchemaVersion;

  @override
  String toString() =>
      'This backup was exported from a newer version of Inner Flare '
      '(schema $fileSchemaVersion) than this app supports (schema '
      '$schemaVersion). Update the app before importing it.';
}
