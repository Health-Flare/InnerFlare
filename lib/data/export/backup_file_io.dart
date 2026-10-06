import 'dart:io';

import 'package:inner_flare/core/files/scratch_files.dart';
import 'package:path/path.dart' as p;

/// The only part of the export/import flow that touches the filesystem:
/// [BackupExporter]/[BackupImporter] (backup_exporter.dart,
/// backup_importer.dart) just gather/parse in-memory data, and the OS
/// share sheet / file picker (lib/features/export/screens) hand off
/// wherever the user actually saves or selects a file.
class BackupFileIO {
  BackupFileIO({DateTime Function()? now}) : _now = now ?? DateTime.now;

  /// Every backup file, encrypted or not, uses this extension: it's
  /// what the import screen's file picker filters on.
  static const extension = 'ifbackup';

  final DateTime Function() _now;

  /// Writes [contents] to a fresh file in the app's scratch folder
  /// ([ScratchFiles]), not the private support directory the encrypted
  /// database lives in, and returns its path. The file is meant to be
  /// handed to the share sheet and then deleted
  /// ([ScratchFiles.shareThenDelete]); anything left behind is removed at
  /// the next launch.
  Future<String> writeTemporaryFile(String contents) async {
    final directory = await ScratchFiles.directory();
    final file = File(p.join(directory.path, fileName()));
    await file.writeAsString(contents, flush: true);
    return file.path;
  }

  /// `backup_<yyyyMMdd>_<HHmmss>.ifbackup`, in UTC. Neutral on purpose
  /// (issue #100): the name the user sees in Files, a chat or a cloud
  /// drive shouldn't say what app made it.
  String fileName() {
    final now = _now().toUtc();
    String two(int n) => n.toString().padLeft(2, '0');
    final stamp =
        '${now.year}${two(now.month)}${two(now.day)}_'
        '${two(now.hour)}${two(now.minute)}${two(now.second)}';
    return 'backup_$stamp.$extension';
  }
}
