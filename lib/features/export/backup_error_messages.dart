import 'package:inner_flare/core/debug/debug_chrome.dart';
import 'package:inner_flare/core/security/backup_encryption.dart';
import 'package:inner_flare/data/export/backup_file_codec.dart';
import 'package:inner_flare/data/export/backup_importer.dart';

/// Shown when an export fails for any reason. Export writes nothing to the
/// database, so "Nothing was changed" is always true.
const exportFailedMessage = "Couldn't create the backup. Nothing was changed.";

/// Shown when an import fails for a reason that isn't one of the known
/// cases below (wrong passphrase, invalid file, newer version).
const importFailedMessage =
    "Couldn't import this backup. Try again, or check the file.";

/// The message the export screen shows for [error] (issue #100).
///
/// Raw exception text can include file paths and internal details, so it's
/// shown only when [showDetail] is true (debug builds, via
/// [showDebugChrome]), under the plain message.
String exportErrorMessage(Object error, {bool showDetail = showDebugChrome}) {
  return _withDetail(exportFailedMessage, error, showDetail);
}

/// The message the import screen shows for [error] (issue #100). Known
/// cases keep their own specific, plain message; anything else gets
/// [importFailedMessage], with the raw text only when [showDetail] is true.
String importErrorMessage(Object error, {bool showDetail = showDebugChrome}) {
  if (error is InvalidBackupFile ||
      error is BackupPassphraseRequired ||
      error is IncorrectBackupPassphrase ||
      error is UnsupportedBackupSchemaVersion) {
    return error.toString();
  }
  return _withDetail(importFailedMessage, error, showDetail);
}

String _withDetail(String message, Object error, bool showDetail) =>
    showDetail ? '$message\n\nDetails (debug builds only): $error' : message;
