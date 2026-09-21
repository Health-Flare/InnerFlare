import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// The only part of the export/import flow that touches the filesystem:
/// [BackupExporter]/[BackupImporter] (backup_exporter.dart,
/// backup_importer.dart) just gather/parse in-memory data, and the OS
/// share sheet / file picker (lib/features/export/screens) hand off
/// wherever the user actually saves or selects a file.
class BackupFileIO {
  /// Every backup file, encrypted or not, uses this extension: it's
  /// what the import screen's file picker filters on.
  static const extension = 'ifbackup';

  /// Writes [contents] to a fresh file in the OS temp directory (not the
  /// app's private support directory the encrypted database lives in;
  /// this file is meant to be handed off via the share sheet, then
  /// discarded) and returns its path.
  Future<String> writeTemporaryFile(String contents) async {
    final directory = await getTemporaryDirectory();
    final file = File(p.join(directory.path, _fileName()));
    await file.writeAsString(contents);
    return file.path;
  }

  String _fileName() {
    final now = DateTime.now().toUtc();
    String two(int n) => n.toString().padLeft(2, '0');
    final stamp =
        '${now.year}${two(now.month)}${two(now.day)}_'
        '${two(now.hour)}${two(now.minute)}${two(now.second)}';
    return 'inner_flare_backup_$stamp.$extension';
  }
}
