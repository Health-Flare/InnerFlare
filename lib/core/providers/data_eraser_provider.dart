import 'package:file_picker/file_picker.dart';
import 'package:inner_flare/core/files/scratch_files.dart';
import 'package:inner_flare/core/security/data_eraser.dart';
import 'package:inner_flare/core/security/db_passphrase_store.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'data_eraser_provider.g.dart';

/// The service behind Settings > Erase all data
/// (docs/features/erase_data.feature). A provider so widget tests can
/// swap in a fake or point it at temp directories.
@riverpod
DataEraser dataEraser(Ref ref) => DataEraser(
  passphraseStore: DbPassphraseStore(),
  supportDirectory: getApplicationSupportDirectory,
  // The export scratch folder, backups older versions left loose in temp,
  // and share_plus's copies (docs/features/export.feature).
  clearTemporaryExports: ScratchFiles.clearAll,
  // Copies of backup files picked for import (Android keeps them in its
  // cache under file_picker/, iOS in the app's tmp folder).
  clearPickedFiles: FilePicker.clearTemporaryFiles,
);
