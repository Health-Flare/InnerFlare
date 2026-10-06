import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Where Inner Flare writes short-lived files that hold the user's data:
/// today that is the backup file handed to the share sheet
/// (docs/features/export.feature, issue #100).
///
/// Backups used to be written loose in the temp directory and never
/// removed, under a name that said what they were. Now they all go in one
/// folder, which is:
/// - emptied at every launch ([sweep]), before the database opens, and
/// - cleaned file by file after each share on phones ([shareThenDelete]).
///
/// This is the only file in `lib/` allowed to call
/// `getTemporaryDirectory()`; a test fails if anything else does, so a new
/// writer can't leave files the sweep doesn't know about.
abstract final class ScratchFiles {
  /// Neutral on purpose, like the database file name: the folder shouldn't
  /// say what app made it or what's inside.
  static const folderName = '.if_scratch';

  /// Backup files Inner Flare 1.0 to 1.3 wrote loose in the temp directory.
  /// The name is specific to this app, so it is safe to delete even where
  /// temp is shared with other programs.
  static final _legacyBackups = RegExp(
    r'^inner_flare_backup_\d{8}_\d{6}\.ifbackup$',
  );

  /// The scratch folder, created if needed.
  static Future<Directory> directory() async {
    final tmp = await getTemporaryDirectory();
    final dir = Directory(p.join(tmp.path, folderName));
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  /// Whether the OS temp directory belongs to this app alone. It does on
  /// Android, iOS and sandboxed macOS. On Windows and Linux it is shared
  /// with every other program the user runs.
  static bool get _tempIsAppPrivate =>
      Platform.isAndroid || Platform.isIOS || Platform.isMacOS;

  /// Removes leftover export files at startup. Call before the database
  /// opens, when no export or share can be in progress. Never throws: a
  /// failed sweep must not stop the app opening.
  ///
  /// [appPrivateTemp] overrides the platform check, for tests.
  static Future<void> sweep({bool? appPrivateTemp}) =>
      clearAll(appPrivateTemp: appPrivateTemp);

  /// Deletes everything in the scratch folder, any backup file an older
  /// version left loose in temp, and (where temp is the app's own)
  /// share_plus's copies. Used by the startup [sweep], and by anything
  /// that has to remove every trace of the user's data (Erase all data).
  /// Never throws.
  ///
  /// [appPrivateTemp] overrides the platform check, for tests.
  static Future<void> clearAll({bool? appPrivateTemp}) async {
    if (kIsWeb) return;
    try {
      final private = appPrivateTemp ?? _tempIsAppPrivate;
      final tmp = await getTemporaryDirectory();
      if (!tmp.existsSync()) return;

      final scratch = Directory(p.join(tmp.path, folderName));
      if (scratch.existsSync()) await scratch.delete(recursive: true);

      for (final entity in tmp.listSync(followLinks: false)) {
        if (entity is! File) continue;
        if (_legacyBackups.hasMatch(p.basename(entity.path))) {
          await _tryDelete(entity);
        }
      }

      // share_plus on Android copies each shared file into cache/share_plus
      // and only clears it at the start of the next share. On Android the
      // temp directory is the app's cache directory.
      final sharePlus = Directory(p.join(tmp.path, 'share_plus'));
      if (private && sharePlus.existsSync()) {
        await sharePlus.delete(recursive: true);
      }
    } on Exception catch (error) {
      // Best effort (a FileSystemException, or no path_provider plugin):
      // the next launch tries again.
      debugPrint('ScratchFiles.clearAll failed: $error');
    }
  }

  /// Runs [share] for the file at [path], then deletes it.
  ///
  /// On Android and iOS the share sheet has handed the file over (Android
  /// copies it first; iOS has finished with it) by the time the share call
  /// returns, so it is deleted straight away, whether the share worked,
  /// was cancelled or threw. On desktop the target app may still be
  /// reading it after the call returns, so it is left for the next
  /// launch's [sweep].
  ///
  /// [deleteNow] overrides the platform check, for tests.
  static Future<T> shareThenDelete<T>(
    String path,
    Future<T> Function() share, {
    bool? deleteNow,
  }) async {
    final now = deleteNow ?? (Platform.isAndroid || Platform.isIOS);
    try {
      return await share();
    } finally {
      if (now) await _tryDelete(File(path));
    }
  }

  static Future<void> _tryDelete(File file) async {
    try {
      if (file.existsSync()) await file.delete();
    } on FileSystemException {
      // Best effort: the next sweep removes it.
    }
  }
}
