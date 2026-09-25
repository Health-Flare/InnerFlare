import 'package:inner_flare/core/providers/security_settings_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'disclaimer_acknowledged_provider.g.dart';

/// Whether the user has continued past the first-run privacy and
/// not-a-medical-device disclaimer
/// (docs/features/first_run_disclaimer.feature).
///
/// Stored in `security_settings`, which is per-device and never exported.
@riverpod
class DisclaimerAcknowledgedNotifier extends _$DisclaimerAcknowledgedNotifier {
  @override
  Future<bool> build() async {
    final repository = await ref.watch(
      securitySettingsRepositoryProvider.future,
    );
    return repository.getDisclaimerAcknowledged();
  }

  /// Persists the acknowledgement, then updates [state] so the gate can
  /// leave the screen. [state] changes only after the write succeeds, so
  /// a failed save leaves the gate up.
  Future<void> acknowledge() async {
    final repository = await ref.read(
      securitySettingsRepositoryProvider.future,
    );
    await repository.setDisclaimerAcknowledged();
    state = const AsyncData(true);
  }
}
