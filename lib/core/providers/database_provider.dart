import 'package:inner_flare/data/database/app_database.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sqflite_common/sqlite_api.dart';

part 'database_provider.g.dart';

/// Opens the encrypted on-device database once per app session and keeps
/// it alive — see [AppDatabase] for what "encrypted" and "on-device" mean
/// in practice.
@Riverpod(keepAlive: true)
Future<Database> appDatabase(Ref ref) {
  return AppDatabase().open();
}
