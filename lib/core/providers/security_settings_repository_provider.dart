import 'package:inner_flare/core/providers/database_provider.dart';
import 'package:inner_flare/data/repositories/security_settings_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'security_settings_repository_provider.g.dart';

@Riverpod(keepAlive: true)
Future<SecuritySettingsRepository> securitySettingsRepository(Ref ref) async {
  final db = await ref.watch(appDatabaseProvider.future);
  return SecuritySettingsRepository(db);
}
