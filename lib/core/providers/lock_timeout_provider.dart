import 'package:inner_flare/core/providers/security_settings_repository_provider.dart';
import 'package:inner_flare/models/lock_timeout.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'lock_timeout_provider.g.dart';

/// The idle-lock timeout setting (docs/features/app_lock.feature): how
/// long the app can sit backgrounded before returning to it requires
/// re-authentication. Backs both [AppLockGate]'s check and the settings
/// screen's picker.
@riverpod
class LockTimeoutNotifier extends _$LockTimeoutNotifier {
  @override
  Future<LockTimeout> build() async {
    final repository = await ref.watch(
      securitySettingsRepositoryProvider.future,
    );
    return repository.getLockTimeout();
  }

  Future<void> setLockTimeout(LockTimeout timeout) async {
    state = AsyncData(timeout);
    final repository = await ref.read(
      securitySettingsRepositoryProvider.future,
    );
    await repository.setLockTimeout(timeout);
  }
}
