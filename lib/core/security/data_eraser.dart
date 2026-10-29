import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:inner_flare/core/security/db_passphrase_store.dart';
import 'package:inner_flare/data/database/app_database.dart';
import 'package:path/path.dart' as p;

/// Thrown by [DataEraser.erase] when the key that unlocks the database
/// couldn't be deleted. Nothing else has been touched: the database is
/// still open and every file is where it was.
class EraseKeyDeletionFailed implements Exception {
  const EraseKeyDeletionFailed(this.cause);

  final Object cause;

  @override
  String toString() => "Couldn't delete the database key: $cause";
}

/// Erase all data (docs/features/erase_data.feature): deletes everything
/// Inner Flare keeps on the device so the next launch is a fresh install.
///
/// Order matters:
/// 1. The key goes first (crypto-shredding). Once it's gone the database
///    file can't be read by anyone, even if deleting the file fails. If
///    the key can't be deleted, [erase] throws [EraseKeyDeletionFailed]
///    before anything else is touched: the database stays open and every
///    file stays put, so the app carries on as before. The connection is
///    still usable after its key is deleted (SQLCipher holds the derived
///    key in memory), so deleting first and closing second is safe.
/// 2. Then, each step best-effort, the database is closed and its file
///    and SQLite's working files deleted, then leftover export files and
///    copies of picked import files are cleared. A failure in any of these
///    doesn't stop the rest, and [erase] still returns normally: the data
///    is unreadable either way.
/// 3. If a database file couldn't be deleted, a marker is left behind and
///    [finishPendingErase] (run by `AppDatabase.open` before it makes a
///    key) deletes the leftovers on the next unlock. Without it, the new
///    key would meet the old file and the app could never open again.
///
/// Everything else the app keeps (settings, the disclaimer flag,
/// dashboard layout, symptom list) lives in the database itself; there's
/// no shared_preferences or other store.
class DataEraser {
  DataEraser({
    required this.passphraseStore,
    required this.supportDirectory,
    required this.clearTemporaryExports,
    this.clearPickedFiles,
    Future<void> Function(File file)? deleteFile,
  }) : _deleteFile = deleteFile ?? _deleteIfExists;

  /// Name of the marker left in the support directory when an erase
  /// deleted the key but couldn't delete every database file.
  static const pendingMarkerName = '.if_reset_pending';

  final DbPassphraseStore passphraseStore;
  final Future<Directory> Function() supportDirectory;
  final Future<void> Function() clearTemporaryExports;
  final Future<void> Function()? clearPickedFiles;
  final Future<void> Function(File file) _deleteFile;

  static Future<void> _deleteIfExists(File file) async {
    if (file.existsSync()) await file.delete();
  }

  /// The database file and every working file SQLite may leave beside it.
  static List<File> databaseFiles(Directory directory) {
    final path = p.join(directory.path, AppDatabase.fileName);
    return [
      for (final suffix in ['', '-wal', '-shm', '-journal'])
        File('$path$suffix'),
    ];
  }

  /// Runs the erase. [closeDatabase] closes the open connection, if any.
  Future<void> erase({Future<void> Function()? closeDatabase}) async {
    try {
      await passphraseStore.delete();
    } catch (error) {
      throw EraseKeyDeletionFailed(error);
    }

    // From here on the data is unreadable; finish everything we can.
    await _bestEffort('close the database', () async {
      await closeDatabase?.call();
    });

    Directory? directory;
    await _bestEffort('find the support folder', () async {
      directory = await supportDirectory();
    });
    final support = directory;
    if (support != null) {
      final marker = File(p.join(support.path, pendingMarkerName));
      await _bestEffort('mark the erase as pending', () async {
        await marker.writeAsString('');
      });
      var allDeleted = true;
      for (final file in databaseFiles(support)) {
        final deleted = await _bestEffort(
          'delete ${p.basename(file.path)}',
          () => _deleteFile(file),
        );
        allDeleted = allDeleted && deleted;
      }
      if (allDeleted) {
        await _bestEffort('clear the pending marker', () async {
          if (marker.existsSync()) await marker.delete();
        });
      }
    }

    await _bestEffort('clear leftover exports', clearTemporaryExports);
    final clearPicked = clearPickedFiles;
    if (clearPicked != null) {
      await _bestEffort('clear picked import files', clearPicked);
    }
  }

  /// Finishes an erase that couldn't delete every database file, before a
  /// new key is made. Does nothing unless the marker is there. Throws if
  /// it can't finish, so the database isn't opened over the old file and
  /// the marker is never left to wipe data logged after this point.
  static Future<void> finishPendingErase({
    required Directory directory,
    required DbPassphraseStore passphraseStore,
  }) async {
    final marker = File(p.join(directory.path, pendingMarkerName));
    if (!marker.existsSync()) return;
    // A key made since the erase (say the app was closed mid-open) only
    // ever protected the old file, which is about to go too.
    await passphraseStore.delete();
    for (final file in databaseFiles(directory)) {
      await _deleteIfExists(file);
    }
    await marker.delete();
  }

  static Future<bool> _bestEffort(
    String step,
    Future<void> Function() action,
  ) async {
    try {
      await action();
      return true;
    } catch (error) {
      debugPrint('Erase all data: could not $step: $error');
      return false;
    }
  }
}
